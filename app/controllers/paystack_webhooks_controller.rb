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
      # The hash should be generated from the request body using your secret key
      hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), paystack_secret_key, request_body)
      
      unless Rack::Utils.secure_compare(hash, signature)
        Rails.logger.warn "Paystack Webhook: Invalid signature. Expected #{hash}, got #{signature}"
        head :unauthorized # Or :bad_request, depending on how strict you want to be
        return
      end
    rescue => e
      Rails.logger.error "Paystack Webhook: Error during signature verification: #{e.message}"
      head :internal_server_error
      return
    end

    # Parse the event payload
    event_payload = JSON.parse(request_body)
    event_type = event_payload['event']

    Rails.logger.info "Paystack Webhook Received: Event Type - #{event_type}, Payload - #{event_payload.inspect}"

    # Handle the event based on its type
    case event_type
    when 'subscription.create'
      handle_subscription_create(event_payload['data'])
    when 'subscription.disable'
      handle_subscription_disable(event_payload['data'])
    when 'subscription.enable'
      handle_subscription_enable(event_payload['data'])
    when 'subscription.not_renew' # Added this event handler
      handle_subscription_not_renew(event_payload['data'])
    when 'charge.success'
      # This event is for successful one-time payments or subscription renewals.
      # For subscriptions, 'invoice.payment_failed' or 'invoice.update' might be more relevant for status changes.
      handle_charge_success(event_payload['data'])
    when 'invoice.create'
      # An invoice has been created, often before a payment attempt for a subscription renewal.
      handle_invoice_create(event_payload['data'])
    when 'invoice.update'
      # An invoice has been updated, e.g., payment successful or failed.
      handle_invoice_update(event_payload['data'])
    when 'invoice.payment_failed'
      handle_invoice_payment_failed(event_payload['data'])
    # Add more event handlers as needed, e.g.:
    # when 'customeridentification.failed'
    # when 'customeridentification.success'
    else
      Rails.logger.info "Paystack Webhook: Unhandled event type '#{event_type}'"
    end

    head :ok # Respond to Paystack quickly with a 200 OK
  end

  private

  def handle_subscription_create(data)
    # Logic to handle a new subscription created via Paystack (e.g., after the first payment on a plan)
    # This is where you'd typically get the definitive paystack_subscription_code and customer_code
    # and update your local Subscription record.
    Rails.logger.info "Handling 'subscription.create': #{data.inspect}"
    # Example: Find user by customer_code, then find or create subscription by subscription_code
    customer_code = data['customer']['customer_code']
    subscription_code = data['subscription_code']
    plan_code = data['plan']['plan_code']
    status = data['status'] # e.g., 'active'

    user = User.find_by(paystack_customer_code: customer_code)
    unless user
      Rails.logger.warn "Paystack Webhook (subscription.create): User not found for customer_code #{customer_code}"
      return
    end

    plan_details = find_plan_by_paystack_code(plan_code) # You might need to make this method accessible or duplicate logic
    unless plan_details
        Rails.logger.warn "Paystack Webhook (subscription.create): Plan details not found for plan_code #{plan_code}"
        return
    end

    subscription = user.subscriptions.find_or_initialize_by(paystack_subscription_code: subscription_code)
    subscription.assign_attributes(
      paystack_plan_code: plan_code,
      status: status.to_sym, # Ensure status from Paystack is converted to symbol for enum
      paystack_customer_code: customer_code,
      plan_name: plan_details[:name],
      interval: plan_details[:interval],
      amount: data['amount'].to_i, # Amount for this subscription instance
      currency: data['plan']['currency'], # Or data['currency'] if available directly
      # Potentially update expires_at based on data['next_payment_date'] or similar
      # expires_at: data['next_payment_date'] ? Time.parse(data['next_payment_date']) : nil
      # authorization_code: data['authorization']['authorization_code'] # if available and relevant
    )
    if subscription.save
        Rails.logger.info "Paystack Webhook (subscription.create): Subscription #{subscription_code} for user #{user.id} saved/updated."
    else
        Rails.logger.error "Paystack Webhook (subscription.create): Failed to save subscription #{subscription_code} for user #{user.id}. Errors: #{subscription.errors.full_messages.join(', ')}"
    end
  end

  def handle_subscription_disable(data)
    Rails.logger.info "Handling 'subscription.disable': #{data.inspect}"
    subscription_code = data['subscription_code']
    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    if subscription
      subscription.update(status: :inactive) # Using enum, assuming 'inactive' is your desired state for disabled
      Rails.logger.info "Paystack Webhook (subscription.disable): Subscription #{subscription_code} marked as inactive."
    else
      Rails.logger.warn "Paystack Webhook (subscription.disable): Subscription #{subscription_code} not found."
    end
  end

  def handle_subscription_enable(data)
    Rails.logger.info "Handling 'subscription.enable': #{data.inspect}"
    subscription_code = data['subscription_code']
    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    if subscription
      subscription.update(status: :active) # Using enum
      Rails.logger.info "Paystack Webhook (subscription.enable): Subscription #{subscription_code} marked as active."
    else
      Rails.logger.warn "Paystack Webhook (subscription.enable): Subscription #{subscription_code} not found."
    end
  end

  def handle_subscription_not_renew(data)
    Rails.logger.info "Handling 'subscription.not_renew': #{data.inspect}"
    subscription_code = data['subscription_code']
    # The 'status' in the payload for not_renew might still be 'active' 
    # but it means it won't renew. You might want a specific status in your system.
    # Or, you might set a flag like `renews_at = nil` or `auto_renew = false`.
    # The `next_payment_date` might be null or in the past.

    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    if subscription
      # Example: Update status to 'non_renewing' or 'cancelled_at_end_of_period'
      # Also consider storing data['cancelled_at'] if provided and relevant.
      subscription.update(status: :non_renewing) # Using enum
      Rails.logger.info "Paystack Webhook (subscription.not_renew): Subscription #{subscription_code} marked as non-renewing."
    else
      Rails.logger.warn "Paystack Webhook (subscription.not_renew): Subscription #{subscription_code} not found."
    end
  end

  def handle_charge_success(data)
    # This event confirms a payment was successful.
    # If it's related to a subscription, you might update the subscription's `paid_at` or `expires_at`.
    Rails.logger.info "Handling 'charge.success': #{data.inspect}"
    # Check if it's a subscription payment (e.g., by looking at metadata or if 'subscription' object exists in data)
    if data['metadata'] && data['metadata']['subscription_code']
      subscription_code = data['metadata']['subscription_code']
      # Or if data['subscription'] && data['subscription']['subscription_code']
    elsif data.dig('subscription', 'subscription_code')
      subscription_code = data.dig('subscription', 'subscription_code')
    elsif data.dig('plan_object', 'plan_code') && data.dig('customer', 'customer_code')
      # Fallback for first payment if subscription_code isn't directly in charge.success
      # We might need to find the subscription via plan_code and customer_code
      # This scenario is better handled by 'subscription.create' or 'invoice.update'
      Rails.logger.info "Paystack Webhook (charge.success): Likely first payment, relying on subscription.create or invoice.update for subscription record."
      return
    else
      Rails.logger.info "Paystack Webhook (charge.success): Not clearly linked to a subscription or subscription_code missing."
      return
    end

    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    if subscription
      # Update relevant fields, e.g., extend expiry, log payment
      # Paystack's `invoice.update` event is often better for managing subscription renewals.
      subscription.update(
        status: :active, # Using enum
        paid_at: Time.parse(data['paid_at']),
        # Potentially update expires_at based on the new billing cycle from Paystack if available
        # For example, if the invoice related to this charge has a next_payment_date
      )
      Rails.logger.info "Paystack Webhook (charge.success): Payment recorded for subscription #{subscription_code}."
    else
      Rails.logger.warn "Paystack Webhook (charge.success): Subscription #{subscription_code} not found."
    end
  end

  def handle_invoice_create(data)
    Rails.logger.info "Handling 'invoice.create': #{data.inspect}"
    # Useful for knowing a renewal attempt is upcoming.
    # You might log this or prepare for a potential payment.
  end

  def handle_invoice_update(data)
    Rails.logger.info "Handling 'invoice.update': #{data.inspect}"
    # This event is crucial for subscription lifecycle management.
    # It tells you if a renewal payment was successful or failed.
    subscription_code = data.dig('subscription', 'subscription_code')
    status = data['status'] # e.g., 'success', 'failed', 'pending'
    paid_at = data['paid_at'] ? Time.parse(data['paid_at']) : nil
    # next_payment_date = data.dig('subscription', 'next_payment_date') ? Time.parse(data.dig('subscription', 'next_payment_date')) : nil
    # amount = data['amount'] # Amount paid for this invoice

    unless subscription_code
      Rails.logger.warn "Paystack Webhook (invoice.update): Missing subscription_code in payload: #{data.inspect}"
      return
    end

    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    unless subscription
      Rails.logger.warn "Paystack Webhook (invoice.update): Subscription #{subscription_code} not found."
      return
    end

    case status
    when 'success', 'paid' # Paystack might use 'paid' or 'success'
      new_status = :active
      subscription.paid_at = paid_at if paid_at
      # subscription.expires_at = next_payment_date if next_payment_date # Update expiry based on Paystack's info
      Rails.logger.info "Paystack Webhook (invoice.update): Subscription #{subscription_code} payment successful. Status: active."
    when 'failed'
      new_status = :inactive # Or a more specific status like 'payment_failed' or 'past_due' if you have one
      Rails.logger.info "Paystack Webhook (invoice.update): Subscription #{subscription_code} payment failed. Status: inactive."
    else
      Rails.logger.info "Paystack Webhook (invoice.update): Invoice for subscription #{subscription_code} has status '#{status}'. No specific status change implemented for this."
      return # Or handle other statuses like 'pending'
    end

    if subscription.update(status: new_status)
      Rails.logger.info "Paystack Webhook (invoice.update): Subscription #{subscription_code} status updated to #{new_status}."
    else
      Rails.logger.error "Paystack Webhook (invoice.update): Failed to update subscription #{subscription_code} to status #{new_status}. Errors: #{subscription.errors.full_messages.join(', ')}"
    end
  end

  def handle_invoice_payment_failed(data)
    Rails.logger.info "Handling 'invoice.payment_failed': #{data.inspect}"
    subscription_code = data.dig('subscription', 'subscription_code')

    unless subscription_code
      Rails.logger.warn "Paystack Webhook (invoice.payment_failed): Missing subscription_code in payload: #{data.inspect}"
      return
    end

    subscription = Subscription.find_by(paystack_subscription_code: subscription_code)
    if subscription
      # Mark as inactive, or a specific status like 'payment_failed' or 'past_due'
      # Consider if multiple failures should lead to 'cancelled' or 'disabled'
      if subscription.update(status: :inactive) # Using enum
        Rails.logger.info "Paystack Webhook (invoice.payment_failed): Subscription #{subscription_code} marked as inactive due to payment failure."
      else 
        Rails.logger.error "Paystack Webhook (invoice.payment_failed): Failed to update subscription #{subscription_code}. Errors: #{subscription.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.warn "Paystack Webhook (invoice.payment_failed): Subscription #{subscription_code} not found."
    end
  end

  # Helper method to find plan details (similar to SubscriptionsController)
  # This might be better placed in a concern or a service object if used in multiple controllers.
  def find_plan_by_paystack_code(plan_code)
    all_plans = {
      "PLN_8i7mnqh3btsuyh5" => { name: "Essentials Plan Monthly", amount: 1048500, interval: "monthly", currency: "NGN", paystack_plan_code: "PLN_8i7mnqh3btsuyh5" },
      "PLN_numptgjwr6es0tq" => { name: "Essentials Plan Yearly", amount: 7635000, interval: "yearly", currency: "NGN", paystack_plan_code: "PLN_numptgjwr6es0tq" },
      "PLN_6n89u8qk8xnn9js" => { name: "Pro Plan Monthly", amount: 2998500, interval: "monthly", currency: "NGN", paystack_plan_code: "PLN_6n89u8qk8xnn9js" },
      "PLN_frc05l69ls4te7e" => { name: "Pro Plan Yearly", amount: 21585000, interval: "yearly", currency: "NGN", paystack_plan_code: "PLN_frc05l69ls4te7e" },
      "PLN_ecxokau9m49554x" => { name: "Business Plan Monthly", amount: 7498500, interval: "monthly", currency: "NGN", paystack_plan_code: "PLN_ecxokau9m49554x" },
      "PLN_pjq5jij5zm0pe6j" => { name: "Business Plan Yearly", amount: 53985000, interval: "yearly", currency: "NGN", paystack_plan_code: "PLN_pjq5jij5zm0pe6j" }
    }
    all_plans[plan_code]
  end
end
