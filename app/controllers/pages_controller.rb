class PagesController < ApplicationController
  allow_unauthenticated_access only: [:home, :pricing, :privacy, :documentation]
  before_action :resume_session, only: [:home, :pricing, :privacy, :documentation]
  
  def home
  end

  def pricing
  end

  def privacy
  end

  def documentation
  end
end
