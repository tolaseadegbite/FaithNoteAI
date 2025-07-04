class PagesController < ApplicationController
  allow_unauthenticated_access only: [:home, :pricing, :privacy, :documentation]
  before_action :resume_session, only: [:home, :pricing, :privacy, :documentation]
  
  def home
  end

  def pricing
    # Fetch all active plans. Ensure your plan names are consistent in the DB.
    # Example plan names: "Essentials Plan Monthly", "Essentials Plan Yearly", 
    # "Pro Plan Monthly", "Pro Plan Yearly", etc.
    @monthly_essentials_plan = Plan.find_by(name: "Essentials Monthly Plan", active: true)
    @yearly_essentials_plan = Plan.find_by(name: "Essentials Yearly Plan", active: true)
    
    @monthly_pro_plan = Plan.find_by(name: "Pro Monthly Plan", active: true)
    @yearly_pro_plan = Plan.find_by(name: "Pro Yearly Plan", active: true)

    @monthly_business_plan = Plan.find_by(name: "Business Monthly Plan", active: true)
    @yearly_business_plan = Plan.find_by(name: "Business Yearly Plan", active: true)

    # It's good practice to handle cases where plans might not be found, 
    # though for a pricing page, they should ideally always exist if active.
    unless @monthly_essentials_plan && @yearly_essentials_plan && @monthly_pro_plan && @yearly_pro_plan && @monthly_business_plan && @yearly_business_plan
      # Log an error or redirect with a notice if plans are missing
      Rails.logger.error "One or more active plans are missing from the database for the pricing page."
      # You might want to redirect or render an error page
      # redirect_to root_path, alert: "Pricing information is currently unavailable. Please try again later."
      # For now, we'll let it proceed, but the view might break if a plan is nil.
    end
  end

  def privacy
  end

  def documentation
  end
end
