class SubscriptionsController < ApplicationController
  before_action :require_authentication
  before_action :set_subscription, only: [:show, :edit, :update]
  before_action :set_paystack_service, only: [:create, :update] # Added :update

  def show
    # @subscription is set by before_action
    # You might want to load associated plan details if not already eager-loaded
    @plan = @subscription.plan
    @pending_plan = Plan.find_by(id: @subscription.pending_plan_id) if @subscription.pending_plan_id
  end

  def edit
    # @subscription is set by before_action
    @current_plan = @subscription.plan
    # Exclude the current plan from the list of available plans for change
    @plans = Plan.active.where.not(id: @current_plan.id)
  end

  def update
    new_plan_id = params.dig(:subscription, :plan_id)
    new_plan = Plan.active.find_by(id: new_plan_id)

    unless new_plan
      redirect_to edit_subscription_path(@subscription), alert: "Invalid plan selected."
      return
    end

    if @subscription.plan_id == new_plan.id
      redirect_to subscription_path(@subscription), notice: "You are already subscribed to this plan."
      return
    end

    # Determine if it's an upgrade or downgrade (basic example based on price)
    # You might have more complex logic (e.g., based on features)
    change_type = new_plan.amount > @subscription.plan.amount ? 'upgrade' : 'downgrade'

    # Schedule the change for the end of the current billing cycle
    # Assumes `next_payment_date` is accurately maintained by webhooks
    # If `next_payment_date` is nil (e.g., for a non-renewing sub that hasn't expired yet),
    # use `expires_at`
    change_at = @subscription.next_payment_date || @subscription.expires_at

    if @subscription.update(
      pending_plan_id: new_plan.id,
      pending_plan_change_type: change_type,
      pending_plan_change_at: change_at,
      status: :active # Keep current subscription active until change occurs
    )
      # Optionally: If Paystack allows, you might want to update the subscription on Paystack
      # to not renew the current plan, or to switch to the new plan at the next cycle.
      # This part is highly dependent on Paystack's API capabilities for plan changes.
      # For now, we're only recording the intent locally.
      # Example: You might call a service to tell Paystack to disable auto-renewal for the current sub
      # paystack_subscriptions_service = PaystackSubscriptions.new(@paystack_obj)
      # paystack_subscriptions_service.disable(code: @subscription.paystack_subscription_code, token: current_user.email) # This needs customer's email token, which is complex to get.
      # A more common flow is to let the current sub expire and then create a new one.

      redirect_to subscription_path(@subscription), notice: "Your plan change to '#{new_plan.name}' is scheduled. It will take effect on #{change_at&.strftime('%B %d, %Y')}."
    else
      @available_plans = Plan.active.where.not(id: @subscription.plan_id)
      render :edit, status: :unprocessable_entity
    end
  rescue PaystackError => e # Catch specific Paystack errors if you make API calls here
    Rails.logger.error "Paystack error during plan change scheduling: #{e.message}"
    redirect_to edit_subscription_path(@subscription), alert: "Could not schedule plan change due to a payment provider error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error scheduling plan change: #{e.message} Backtrace: #{e.backtrace.join("\n")}"
    redirect_to edit_subscription_path(@subscription), alert: "An unexpected error occurred while scheduling your plan change."
  end

  def create
    
    plan = Plan.find_by(id: params[:plan_id], active: true)

    unless plan
      redirect_to pricing_path, alert: "Invalid plan selected or plan not found."
      return
    end

    # Ensure @paystack_obj is initialized (moved to set_paystack_service)
    # paystack_public_key = Rails.application.credentials.paystack[:public_key]
    # paystack_secret_key = Rails.application.credentials.paystack[:secret_key]
    # @paystack_obj = Paystack.new(paystack_public_key, paystack_secret_key)

    begin
      customers_service = PaystackCustomers.new(paystack_obj)
      customer_code = current_user.paystack_customer_code

      unless customer_code
        # Split the name into first and last if possible, otherwise use the full name as first_name
        user_name_parts = current_user.name.to_s.split(' ', 2)
        first_name = user_name_parts[0]
        last_name = user_name_parts[1] # This will be nil if there's no space in the name

        customer_payload = { email: current_user.email }
        customer_payload[:first_name] = first_name if first_name.present?
        customer_payload[:last_name] = last_name if last_name.present?

        customer_response = customers_service.create(customer_payload)

        if customer_response['status']
          customer_code = customer_response['data']['customer_code']
          current_user.update(paystack_customer_code: customer_code) 
        else
          Rails.logger.error "Paystack Customer Creation Error: #{customer_response['message']}"
          redirect_to pricing_path, alert: "Failed to create customer profile: #{customer_response['message']}"
          return
        end
      end

      transactions_service = PaystackTransactions.new(paystack_obj)
      reference = "faithnote_sub_#{SecureRandom.hex(10)}"

      transaction_params = {
        reference: reference,
        amount: plan.amount, # Use plan.amount (ensure it's in kobo)
        email: current_user.email,
        currency: plan.currency, 
        plan: plan.paystack_plan_code, # Use plan.paystack_plan_code
        callback_url: callback_subscriptions_url,
        customer: customer_code, 
        metadata: {
          user_id: current_user.id,
          plan_id: plan.id, # Store plan.id in metadata
          plan_name: plan.name,
          interval: plan.interval,
          custom_fields: [
            { 
              display_name: "Plan", 
              variable_name: "plan_name", 
              value: plan.name
            }
          ]
        }
      }
      
      result = transactions_service.initializeTransaction(transaction_params)

      if result['status'] && result['data']['authorization_url']
        session[:paystack_reference] = reference
        session[:paystack_plan_id] = plan.id # Store plan.id in session
        redirect_to result['data']['authorization_url'], allow_other_host: true
      else
        Rails.logger.error "Paystack Initialization Error: #{result['message']}"
        redirect_to pricing_path, alert: "Failed to initialize subscription: #{result['message']}"
      end

    rescue PaystackBadKeyError => e
      Rails.logger.error "Paystack API Key Error: #{e.message}"
      redirect_to pricing_path, alert: "Paystack API key error: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Paystack Standard Error: #{e.message} Backtrace: #{e.backtrace.join("\n")}"
      redirect_to pricing_path, alert: "An unexpected error occurred: #{e.message}"
    end
  end

  def callback
    reference = params[:trxref] || params[:reference]
    paystack_plan_id_from_session = session.delete(:paystack_plan_id) # Retrieve plan_id

    if reference.blank?
      redirect_to pricing_path, alert: "Transaction reference missing."
      return
    end

    paystack_public_key = Rails.application.credentials.paystack[:public_key]
    paystack_secret_key = Rails.application.credentials.paystack[:secret_key]

    paystack_obj = Paystack.new(paystack_public_key, paystack_secret_key)
    transactions_service = PaystackTransactions.new(paystack_obj)

    begin
      verification_result = transactions_service.verify(reference)

      if verification_result['status'] && verification_result['data']['status'] == 'success'
        data = verification_result['data']
        customer_data = data['customer']
        authorization_data = data['authorization']
        
        plan = nil
        if paystack_plan_id_from_session
          plan = Plan.find_by(id: paystack_plan_id_from_session)
        elsif data.dig('plan', 'plan_code').present? # Fallback to plan_code from Paystack if session miss
             plan = Plan.find_by(paystack_plan_code: data.dig('plan', 'plan_code'))
        elsif data.dig('metadata', 'plan_id').present? # Fallback to plan_id from metadata
             plan = Plan.find_by(id: data.dig('metadata', 'plan_id'))
        end

        unless plan
          Rails.logger.error "Paystack Callback Error: Could not determine plan for reference: #{reference}. Session plan_id: #{paystack_plan_id_from_session}, Paystack plan_code: #{data.dig('plan', 'plan_code')}"
          redirect_to pricing_path, alert: "Could not determine subscription plan. Please contact support."
          return
        end

        # Ensure user has a paystack_customer_code, update if necessary from verification
        if current_user.paystack_customer_code.blank? && customer_data && customer_data['customer_code']
          current_user.update(paystack_customer_code: customer_data['customer_code'])
        end

        # Create or update subscription
        # Paystack might return a subscription_code directly if the plan initialization creates one
        # or it might be part of a separate webhook event (e.g., subscription.create)
        # For now, we'll use the transaction reference or a generated one if specific sub code isn't there.
        # The actual `paystack_subscription_code` will ideally come from a webhook.
        paystack_subscription_code = data['subscription_code'] || data['id'] 

        subscription = current_user.subscriptions.find_or_initialize_by(paystack_subscription_code: paystack_subscription_code)
        
        subscription.assign_attributes(
          paystack_plan_code: plan.paystack_plan_code,
          plan_id: plan.id, # Store foreign key to plan
          status: :active, 
          paystack_customer_code: customer_data['customer_code'],
          amount: data['amount'].to_i, 
          currency: data['currency'],
          plan_name: plan.name,
          interval: plan.interval,
          paystack_transaction_reference: reference,
          authorization_code: authorization_data['authorization_code'],
          card_type: authorization_data['card_type'],
          last_four_digits: authorization_data['last4'],
          exp_month: authorization_data['exp_month'],
          exp_year: authorization_data['exp_year'],
          bank: authorization_data['bank'],
          paid_at: Time.parse(data['paid_at']) # Ensure correct parsing of timestamp
        )

        if subscription.save
          # Clear session variables used during transaction
          session.delete(:paystack_reference)
          # session.delete(:paystack_plan_code) # Already deleted above

          redirect_to dashboard_path, notice: "Subscription activated successfully!"
        else
          Rails.logger.error "Subscription Save Error: #{subscription.errors.full_messages.join(', ')} for reference: #{reference}"
          redirect_to pricing_path, alert: "Failed to save subscription details: #{subscription.errors.full_messages.join(', ')}"
        end
      elsif verification_result['status'] # Transaction was found but not successful
        Rails.logger.warn "Paystack Verification Warning: Transaction #{reference} was not successful. Status: #{verification_result['data']['status']}, Gateway Response: #{verification_result['data']['gateway_response']}"
        redirect_to pricing_path, alert: "Payment was not successful. Status: #{verification_result['data']['gateway_response']}"
      else # Verification call itself failed
        Rails.logger.error "Paystack Verification Error: #{verification_result['message']} for reference: #{reference}"
        redirect_to pricing_path, alert: "Failed to verify transaction: #{verification_result['message']}"
      end

    rescue PaystackBadKeyError => e
      Rails.logger.error "Paystack API Key Error during callback: #{e.message}"
      redirect_to pricing_path, alert: "Paystack API key error during callback: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Paystack Callback Standard Error: #{e.message} Backtrace: #{e.backtrace.join("\n")}"
      redirect_to pricing_path, alert: "An unexpected error occurred during callback: #{e.message}"
    end
  end

  private

  def set_subscription
    # Assuming users can only have one active/pending subscription at a time for simplicity.
    # You might need more complex logic if users can have multiple subscriptions.
    @subscription = current_user.subscriptions.where(status: [:active, :pending, :non_renewing, :incomplete]).order(created_at: :desc).first
    unless @subscription
      redirect_to pricing_path, alert: "No active subscription found to manage."
    end
  end

  def set_paystack_service
    paystack_public_key = Rails.application.credentials.paystack[:public_key]
    paystack_secret_key = Rails.application.credentials.paystack[:secret_key]
    @paystack_obj = Paystack.new(paystack_public_key, paystack_secret_key)
  rescue PaystackBadKeyError => e
    Rails.logger.error "Paystack API Key Error: #{e.message}"
    # Handle appropriately, maybe redirect with alert or raise
    redirect_to root_path, alert: "Payment provider configuration error. Please contact support."
  end

end
