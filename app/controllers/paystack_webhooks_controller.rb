class PaystackWebhooksController < ApplicationController
  # Skip CSRF protection for webhook endpoint, as Paystack won't send a CSRF token
  skip_before_action :verify_authenticity_token

  def create
    # Verify the webhook signature
    paystack_secret_key = Rails.application.credentials.paystack[:secret_key]
    request_body = request.body.read
    signature = request.headers['X-Paystack-Signature']

    unless paystack_secret_key.present? && signature.present?
      Rails.logger.warn "Paystack Webhook: Missing secret key or signature."
      head :bad_request
      return
    end

    begin
      hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), paystack_secret_key, request_body)
      unless Rack::Utils.secure_compare(hash, signature)
        Rails.logger.warn "Paystack Webhook: Invalid signature. Expected #{hash}, got #{signature}"
        head :unauthorized
        return
      end
    rescue => e
      Rails.logger.error "Paystack Webhook: Error during signature verification: #{e.message}"
      head :internal_server_error
      return
    end

    event_payload = JSON.parse(request_body)
    event_type = event_payload['event']
    event_data = event_payload['data'] # Consistently use event_data for the payload's 'data' object

    Rails.logger.info "Paystack Webhook Received: Event Type - #{event_type}, Payload Data: #{event_data.inspect}"

    # Ensure critical data is present
    subscription_code = event_data['subscription']&.is_a?(Hash) ? event_data['subscription']['subscription_code'] : event_data['subscription_code']
    customer_code = event_data['customer']&.is_a?(Hash) ? event_data['customer']['customer_code'] : event_data['customer_code'] 
    # For charge.success, subscription code might be nested differently or within authorization
    if event_type == 'charge.success'
      # Attempt to get subscription_code from authorization if it's a recurring charge
      if event_data['authorization'] && event_data['authorization']['reusable'] && event_data['plan_object']
        # This looks like a subscription payment. We need to find our subscription via customer and plan, or ideally, if Paystack includes a subscription_code.
        # Paystack's charge.success for subscriptions often lacks a direct subscription_code in event_data top level.
        # It might be in event_data['plan_object']['subscriptions'] (array) or we might need to rely on customer and plan.
        # For simplicity, we'll assume we can find the subscription via customer and that the charge pertains to an active subscription.
        # A more robust solution might involve looking up the subscription by authorization_code if that's stored and linked.
        # For now, let's assume customer_code is reliable for finding the user.
      elsif event_data['subscription'] && event_data['subscription']['subscription_code'] # Direct subscription object in charge.success
        subscription_code = event_data['subscription']['subscription_code']
      end
    end

    user = User.find_by(paystack_customer_code: customer_code)
    subscription = user&.subscriptions&.find_by(paystack_subscription_code: subscription_code) if user && subscription_code.present?

    # If subscription not found by code, try to find an active one for the user if it's a charge.success for a known plan
    if subscription.nil? && user && event_type == 'charge.success' && event_data['plan'] # plan is plan_code here
      plan = Plan.find_by(paystack_plan_code: event_data['plan'])
      subscription = user.subscriptions.active.find_by(plan_id: plan.id) if plan
    end

    # Fallback for invoice.payment_success or invoice.update if subscription_code is in invoice items or top level
    if subscription.nil? && user && (event_type == 'invoice.payment_success' || event_type == 'invoice.update')
      # Try to find subscription_code within invoice details if available
      # This part is highly dependent on Paystack's invoice structure for subscriptions
      if event_data['subscription'] && event_data['subscription']['subscription_code']
        subscription_code = event_data['subscription']['subscription_code']
        subscription = user.subscriptions.find_by(paystack_subscription_code: subscription_code)
      elsif event_data['lines']&.first&.[]('subscription_code') # Check invoice lines
        subscription_code = event_data['lines'].first['subscription_code']
        subscription = user.subscriptions.find_by(paystack_subscription_code: subscription_code)
      end
    end

    unless user
      Rails.logger.warn "Paystack Webhook: User not found for customer_code: #{customer_code}. Event: #{event_type}"
      head :not_found
      return
    end

    # Process based on event type
    case event_type
    when 'subscription.create'
      handle_subscription_create(event_data, user)
    when 'subscription.disable'
      handle_subscription_disable(event_data, subscription)
    when 'subscription.not_renew' # Or subscription.expiring, subscription.cancelled
      handle_subscription_not_renew(event_data, subscription)
    when 'charge.success'
      handle_charge_success(event_data, user, subscription) # Pass user as well for safety
    when 'invoice.update', 'invoice.payment_success' # invoice.create might also be relevant for dates
      handle_invoice_update(event_data, user, subscription)
    else
      Rails.logger.info "Paystack Webhook: Unhandled event type: #{event_type}"
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Paystack Webhook: Invalid JSON payload: #{e.message}"
    head :bad_request
  rescue => e
    Rails.logger.error "Paystack Webhook: Error processing webhook: #{e.message}\n#{e.backtrace.join("\n")}"
    head :internal_server_error
  end

  private

  def handle_subscription_create(data, user)
    # This might be redundant if subscription is created/updated in callback_subscriptions_controller
    # but good for reconciliation.
    # Ensure plan_id is set based on data['plan']['plan_code']
    plan = Plan.find_by(paystack_plan_code: data.dig('plan', 'plan_code'))
    unless plan
      Rails.logger.error "Paystack Webhook (subscription.create): Plan not found for code #{data.dig('plan', 'plan_code')}"
      return
    end

    subscription = user.subscriptions.find_or_initialize_by(paystack_subscription_code: data['subscription_code'])
    subscription.assign_attributes(
      plan_id: plan.id,
      paystack_plan_code: plan.paystack_plan_code, # Store the plan code from the plan model
      paystack_customer_code: data.dig('customer', 'customer_code'),
      amount: data.dig('amount'), # Amount from the subscription event
      currency: data.dig('plan', 'currency'), # Currency from the plan within subscription
      status: data['status'], # e.g., active, non-renewing, complete
      authorization_code: data.dig('authorization', 'authorization_code'),
      next_payment_date: data['next_payment_date'] ? Time.parse(data['next_payment_date']) : nil,
      expires_at: calculate_expires_at(data['next_payment_date'], plan.interval, data['most_recent_invoice']&.dig('period_end')),
      # If 'cron_expression' and 'start_date' are available, they can also determine billing cycle.
      # For fixed cycle, 'expires_at' might be more aligned with 'next_payment_date' or invoice period end.
      bank: data.dig('authorization', 'bank'),
      card_type: data.dig('authorization', 'card_type'),
      last_four_digits: data.dig('authorization', 'last4'),
      exp_month: data.dig('authorization', 'exp_month'),
      exp_year: data.dig('authorization', 'exp_year'),
      plan_name: data.dig('plan', 'name'),
      interval: data.dig('plan', 'interval')
    )
    if subscription.save
      Rails.logger.info "Paystack Webhook: Subscription #{data['status']} for user #{user.id}, subscription_code: #{data['subscription_code']}."
    else
      Rails.logger.error "Paystack Webhook: Failed to save subscription for user #{user.id}: #{subscription.errors.full_messages.join(', ')}"
    end
  end

  def handle_subscription_disable(data, subscription)
    if subscription
      subscription.update(status: 'cancelled', expires_at: Time.current) # Or use a date from Paystack if available
      Rails.logger.info "Paystack Webhook: Subscription disabled for subscription_code: #{data['subscription_code']}."
    else
      Rails.logger.warn "Paystack Webhook (subscription.disable): Subscription not found for code #{data['subscription_code']}"
    end
  end

  def handle_subscription_not_renew(data, subscription)
    if subscription
      # 'subscription.not_renew' means it will expire at the end of the current period.
      # 'expires_at' should already reflect this from the last successful charge or invoice update.
      # We just update the status to reflect it's not renewing.
      subscription.update(status: 'non-renewing') # Or 'cancelled' if that's your preferred status
      Rails.logger.info "Paystack Webhook: Subscription set to not renew for code: #{data['subscription_code']}. Will expire on #{subscription.expires_at}."
    else
      Rails.logger.warn "Paystack Webhook (subscription.not_renew): Subscription not found for code #{data['subscription_code']}"
    end
  end

  def handle_charge_success(data, user, subscription)
    # This event is crucial. It confirms a payment was made.
    # If this charge is for a subscription, update its dates and status.

    # If subscription is nil, try to find it via authorization if it's a recurring payment
    if subscription.nil? && data.dig('authorization', 'authorization_code') && user
      subscription = user.subscriptions.find_by(authorization_code: data.dig('authorization', 'authorization_code'), status: ['active', 'non-renewing'])
    end

    # If still nil, and it's a plan payment, try to find by plan and user
    if subscription.nil? && data.dig('plan', 'plan_code') && user
      plan = Plan.find_by(paystack_plan_code: data.dig('plan', 'plan_code'))
      if plan
        subscription = user.subscriptions.active_or_non_renewing.find_by(plan_id: plan.id)
      end
    end

    unless subscription
      Rails.logger.warn "Paystack Webhook (charge.success): Subscription not found. Customer: #{data.dig('customer','email')}, Plan: #{data.dig('plan','name')}, Amount: #{data['amount']}. This might be a one-time payment or an unlinked subscription."
      # If it's a first payment for a new subscription not yet in your DB via subscription.create, this might be an issue.
      # The SubscriptionsController callback should ideally create the subscription record first.
      return
    end

    # If a plan change is pending and this charge signifies the start of the new period
    if subscription.pending_plan_id? && (subscription.pending_plan_change_at.nil? || Time.current >= subscription.pending_plan_change_at || Time.current >= subscription.expires_at)
      new_plan = Plan.find_by(id: subscription.pending_plan_id)
      if new_plan
        Rails.logger.info "Paystack Webhook (charge.success): Applying pending plan change for subscription #{subscription.id} to plan #{new_plan.name}."
        subscription.plan_id = new_plan.id
        subscription.paystack_plan_code = new_plan.paystack_plan_code
        subscription.amount = new_plan.amount # Update amount to new plan's amount
        subscription.interval = new_plan.interval
        subscription.plan_name = new_plan.name
        
        subscription.pending_plan_id = nil
        subscription.pending_plan_change_type = nil
        subscription.pending_plan_change_at = nil
      else
        Rails.logger.error "Paystack Webhook (charge.success): Pending plan ID #{subscription.pending_plan_id} not found for subscription #{subscription.id}."
      end
    end

    # Update subscription details based on the charge
    # next_payment_date and expires_at should ideally come from an invoice.update or subscription.update event
    # For charge.success, we confirm payment and rely on other events for future dates if possible.
    # However, if Paystack provides `next_payment_date` in `plan_object` or `subscription` sub-object, use it.
    # This part needs careful checking against actual Paystack payload for charge.success on subscriptions.

    paid_at_time = data['paid_at'] ? Time.parse(data['paid_at']) : Time.current
    current_plan = subscription.plan # This is now the potentially new plan

    # Attempt to get next_payment_date from various possible locations in payload
    next_payment_date_str = data.dig('subscription', 'next_payment_date') || data.dig('plan_object', 'next_payment_date')
    next_payment_date_val = next_payment_date_str ? Time.parse(next_payment_date_str) : nil

    # If next_payment_date is not directly in charge.success, calculate it based on current plan
    # This is a fallback and might be less accurate than Paystack's own date.
    next_payment_date_val ||= calculate_next_payment_from_current(paid_at_time, current_plan.interval)
    
    new_expires_at = calculate_expires_at(next_payment_date_val.to_s, current_plan.interval) 

    update_attrs = {
      status: 'active', # A successful charge usually means the subscription is active
      paid_at: paid_at_time,
      next_payment_date: next_payment_date_val,
      expires_at: new_expires_at,
      # Update card details if they've changed and are provided
      authorization_code: data.dig('authorization', 'authorization_code') || subscription.authorization_code,
      bank: data.dig('authorization', 'bank') || subscription.bank,
      card_type: data.dig('authorization', 'card_type') || subscription.card_type,
      last_four_digits: data.dig('authorization', 'last4') || subscription.last_four_digits,
      exp_month: data.dig('authorization', 'exp_month') || subscription.exp_month,
      exp_year: data.dig('authorization', 'exp_year') || subscription.exp_year
    }

    if subscription.update(update_attrs)
      Rails.logger.info "Paystack Webhook: charge.success processed for subscription #{subscription.id}. Next payment: #{subscription.next_payment_date}, Expires: #{subscription.expires_at}."
    else
      Rails.logger.error "Paystack Webhook (charge.success): Failed to update subscription #{subscription.id}: #{subscription.errors.full_messages.join(', ')}"
    end
  end

  def handle_invoice_update(data, user, subscription)
    # invoice.update can signal many things. We're interested if it finalizes a period or provides new dates.
    # Particularly, if an invoice is paid ('status' == 'success') or if it provides 'next_payment_date'.

    # Try to find subscription if not passed directly (e.g. if webhook is just for an invoice not directly linked in initial lookup)
    if subscription.nil? && data.dig('subscription', 'subscription_code') && user
      subscription = user.subscriptions.find_by(paystack_subscription_code: data.dig('subscription', 'subscription_code'))
    end
    
    # If invoice is for a specific subscription not found by the generic lookup
    if subscription.nil? && data.dig('subscription_code') && user # some payloads might have subscription_code at top level of data
        subscription = user.subscriptions.find_by(paystack_subscription_code: data['subscription_code'])
    end

    unless subscription
      Rails.logger.warn "Paystack Webhook (invoice.update/payment_success): Subscription not found. Invoice ID: #{data['invoice_code']}. Customer: #{data.dig('customer','email')}."
      return
    end

    # If a plan change is pending and this invoice update signifies the start of the new period
    # This condition might be similar to charge.success, depends on when Paystack sends invoice.update vs charge.success for renewals
    # We check if the invoice period start aligns with when the change should occur
    invoice_period_start = data.dig('period', 'start') ? Time.at(data.dig('period', 'start')).to_datetime : nil
    
    if subscription.pending_plan_id? && 
       ( (subscription.pending_plan_change_at && invoice_period_start && invoice_period_start >= subscription.pending_plan_change_at.beginning_of_day) || 
         (subscription.expires_at && invoice_period_start && invoice_period_start >= subscription.expires_at.beginning_of_day) )
      
      new_plan = Plan.find_by(id: subscription.pending_plan_id)
      if new_plan
        Rails.logger.info "Paystack Webhook (invoice.update): Applying pending plan change for subscription #{subscription.id} to plan #{new_plan.name}."
        subscription.plan_id = new_plan.id
        subscription.paystack_plan_code = new_plan.paystack_plan_code
        subscription.amount = new_plan.amount
        subscription.interval = new_plan.interval
        subscription.plan_name = new_plan.name

        subscription.pending_plan_id = nil
        subscription.pending_plan_change_type = nil
        subscription.pending_plan_change_at = nil
      else
        Rails.logger.error "Paystack Webhook (invoice.update): Pending plan ID #{subscription.pending_plan_id} not found for subscription #{subscription.id}."
      end
    end

    # Update dates if the invoice is paid and provides them
    # The 'paid_at', 'next_payment_date', 'period_start', 'period_end' fields are key here.
    if data['paid'] == true || data['status'] == 'success' # Check if invoice is marked as paid
      current_plan = subscription.plan # This is now the potentially new plan
      paid_at_time = data['paid_at'] ? Time.parse(data['paid_at']) : (data['date'] ? Time.parse(data['date']) : Time.current)
      
      # Paystack's invoice object for subscriptions often has 'subscription_data' which contains 'next_invoice_date'
      # or the main subscription object within the invoice payload might have 'next_payment_date'
      next_payment_date_str = data.dig('subscription', 'next_payment_date') || data.dig('subscription_data', 'next_invoice_date')
      next_payment_date_val = next_payment_date_str ? Time.parse(next_payment_date_str) : nil
      
      # If not found, try to calculate from period_end or paid_at + interval
      period_end_str = data.dig('period', 'end') ? Time.at(data.dig('period', 'end')).to_datetime.iso8601 : nil
      expires_at_val = period_end_str ? Time.parse(period_end_str) : calculate_expires_at(next_payment_date_val.to_s, current_plan.interval, nil)
      next_payment_date_val ||= calculate_next_payment_from_current(paid_at_time, current_plan.interval, expires_at_val)
      
      update_attrs = {
        status: 'active',
        paid_at: paid_at_time,
        next_payment_date: next_payment_date_val,
        expires_at: expires_at_val,
        # Update other relevant fields if present in invoice data (e.g. amount if it changed)
        amount: data.dig('amount') || subscription.amount # Amount from invoice if available
      }

      if subscription.update(update_attrs)
        Rails.logger.info "Paystack Webhook: invoice.update/payment_success processed for subscription #{subscription.id}. Next payment: #{subscription.next_payment_date}, Expires: #{subscription.expires_at}."
      else
        Rails.logger.error "Paystack Webhook (invoice.update): Failed to update subscription #{subscription.id}: #{subscription.errors.full_messages.join(', ')}"
      end
    elsif data['next_payment_date'] # Even if not paid, if it updates next_payment_date
      next_payment_date_val = Time.parse(data['next_payment_date'])
      current_plan = subscription.plan
      expires_at_val = calculate_expires_at(data['next_payment_date'], current_plan.interval, data.dig('period', 'end') ? Time.at(data.dig('period', 'end')).to_datetime.iso8601 : nil)
      if subscription.update(next_payment_date: next_payment_date_val, expires_at: expires_at_val)
         Rails.logger.info "Paystack Webhook: invoice.update updated next_payment_date for subscription #{subscription.id} to #{next_payment_date_val}."
      else
        Rails.logger.error "Paystack Webhook (invoice.update): Failed to update next_payment_date for subscription #{subscription.id}: #{subscription.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.info "Paystack Webhook: invoice.update event for subscription #{subscription.id} did not result in changes. Status: #{data['status']}, Paid: #{data['paid']}."
    end
  end

  def calculate_expires_at(next_payment_date_str, interval, period_end_str = nil)
    # If period_end is provided by Paystack (e.g. from an invoice), prefer that as expires_at.
    if period_end_str
      begin
        return Time.parse(period_end_str)
      rescue ArgumentError, TypeError
        Rails.logger.warn "Paystack Webhook: Could not parse period_end_str: #{period_end_str}"
      end
    end 
    
    # Otherwise, expires_at is typically the same as next_payment_date for non-prorated fixed cycles.
    if next_payment_date_str
      begin
        return Time.parse(next_payment_date_str)
      rescue ArgumentError, TypeError
        Rails.logger.warn "Paystack Webhook: Could not parse next_payment_date_str for expires_at: #{next_payment_date_str}"
      end
    end
    
    # Fallback: if next_payment_date is also nil, calculate from now + interval (less ideal)
    base_time = Time.current
    case interval.downcase
    when 'monthly'
      base_time + 1.month
    when 'yearly', 'annually'
      base_time + 1.year
    # Add other intervals as needed: 'daily', 'weekly', 'quarterly', 'biannually'
    when 'daily'
      base_time + 1.day
    when 'weekly'
      base_time + 1.week
    when 'quarterly'
      base_time + 3.months
    when 'biannually'
      base_time + 6.months
    else
      Rails.logger.warn "Paystack Webhook: Unknown interval '#{interval}' for calculating expires_at."
      base_time + 1.month # Default fallback
    end
  end

  def calculate_next_payment_from_current(current_time, interval, known_expires_at = nil)
    # If we have a known expires_at (which might be the new period_end from an invoice),
    # that IS the next_payment_date for a fixed cycle that just renewed.
    return known_expires_at if known_expires_at

    # Otherwise, calculate from current_time + interval
    case interval.downcase
    when 'monthly'
      current_time + 1.month
    when 'yearly', 'annually'
      current_time + 1.year
    when 'daily'
      current_time + 1.day
    when 'weekly'
      current_time + 1.week
    when 'quarterly'
      current_time + 3.months
    when 'biannually'
      current_time + 6.months
    else
      Rails.logger.warn "Paystack Webhook: Unknown interval '#{interval}' for calculating next_payment_date."
      current_time + 1.month # Default fallback
    end
  end

end
