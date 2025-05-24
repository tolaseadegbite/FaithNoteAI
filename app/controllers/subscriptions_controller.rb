class SubscriptionsController < ApplicationController
  before_action :authenticate_user! 

  def create
    plan_name = params[:plan_name]
    interval = params[:interval] 

    plan_details = get_plan_details(plan_name, interval)

    if plan_details.nil? || plan_details[:paystack_plan_code].blank?
      redirect_to pricing_path, alert: "Invalid plan selected or Paystack plan code missing."
      return
    end

    paystack_public_key = Rails.application.credentials.paystack[:public_key]
    paystack_secret_key = Rails.application.credentials.paystack[:secret_key]

    paystack_obj = Paystack.new(paystack_public_key, paystack_secret_key)

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
        amount: plan_details[:amount], 
        email: current_user.email,
        currency: plan_details[:currency], 
        plan: plan_details[:paystack_plan_code],
        callback_url: callback_subscriptions_url,
        customer: customer_code, 
        metadata: {
          user_id: current_user.id,
          plan_name: plan_details[:name],
          interval: interval,
          custom_fields: [
            { 
              display_name: "Plan", 
              variable_name: "plan_name", 
              value: "#{plan_name} (#{interval})"
            }
          ]
        }
      }
      
      result = transactions_service.initializeTransaction(transaction_params)

      if result['status'] && result['data']['authorization_url']
        session[:paystack_reference] = reference
        session[:paystack_plan_code] = plan_details[:paystack_plan_code] 
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
    paystack_plan_code_from_session = session.delete(:paystack_plan_code) # Retrieve and remove from session

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
        plan_object = data['plan_object'] # This might contain plan details if a plan was used

        # Find the plan details using the code stored in session or from verification data
        # The paystack_plan_code from session is more reliable if Paystack doesn't return it clearly
        paystack_plan_code = paystack_plan_code_from_session || (plan_object && plan_object['plan_code'])

        unless paystack_plan_code
          Rails.logger.error "Paystack Callback Error: Plan code missing in session and verification data for reference: #{reference}"
          redirect_to pricing_path, alert: "Could not determine subscription plan. Please contact support."
          return
        end

        plan_details = find_plan_by_paystack_code(paystack_plan_code)

        unless plan_details
          Rails.logger.error "Paystack Callback Error: Could not find plan details for plan_code: #{paystack_plan_code} from reference: #{reference}"
          redirect_to pricing_path, alert: "Invalid plan details retrieved. Please contact support."
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
        paystack_subscription_code = data['subscription_code'] || data['id'] # Using transaction ID as a placeholder if no sub_code

        subscription = current_user.subscriptions.find_or_initialize_by(paystack_subscription_code: paystack_subscription_code)
        
        subscription.assign_attributes(
          paystack_plan_code: paystack_plan_code,
          status: 'active', # Assuming successful payment means active subscription
          paystack_customer_code: customer_data['customer_code'],
          amount: data['amount'].to_i, # Amount is in kobo/cents from Paystack
          currency: data['currency'],
          plan_name: plan_details[:name],
          interval: plan_details[:interval],
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

  def get_plan_details(plan_name, interval)
    # Ensure amounts are in kobo (NGN 1 = 100 kobo)
    plans = {
      "Essentials Plan" => {
        "monthly" => { name: "Essentials Plan Monthly", amount: 1048500, paystack_plan_code: "PLN_8i7mnqh3btsuyh5", currency: "NGN", interval: "monthly" },
        "yearly" => { name: "Essentials Plan Yearly", amount: 7635000, paystack_plan_code: "PLN_numptgjwr6es0tq", currency: "NGN", interval: "yearly" }
      },
      "Pro Plan" => {
        "monthly" => { name: "Pro Plan Monthly", amount: 2998500, paystack_plan_code: "PLN_6n89u8qk8xnn9js", currency: "NGN", interval: "monthly" },
        "yearly" => { name: "Pro Plan Yearly", amount: 21585000, paystack_plan_code: "PLN_frc05l69ls4te7e", currency: "NGN", interval: "yearly" }
      },
      "Business Plan" => {
        "monthly" => { name: "Business Plan Monthly", amount: 7498500, paystack_plan_code: "PLN_ecxokau9m49554x", currency: "NGN", interval: "monthly" },
        "yearly" => { name: "Business Plan Yearly", amount: 53985000, paystack_plan_code: "PLN_pjq5jij5zm0pe6j", currency: "NGN", interval: "yearly" }
      }
    }

    plan_data = plans.dig(plan_name, interval.downcase)
    # Ensure interval is part of the returned hash if it's not already
    # It seems it's already there, but good to double check for consistency
    plan_data[:interval] = interval.downcase if plan_data && plan_data[:interval].blank?
    plan_data
  end

  def find_plan_by_paystack_code(plan_code)
    # This is needed for webhook processing or verifying existing subscriptions
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

  def authenticate_user!
    unless current_user
      redirect_to new_session_path, alert: "You need to be logged in to subscribe."
    end
  end

  def current_user
    Current.user # Use Current.user as per the provided Authentication concern
  end
end
