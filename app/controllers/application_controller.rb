class ApplicationController < ActionController::Base

  prepend_before_filter :get_api_key

  include ErrorResponseActions
  
  rescue_from CanCan::AccessDenied, :with => :authorization_error
  rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found

  private
  def get_api_key
    params.delete(:api_key)
    if request.headers["X-API-KEY"]
      params[:api_key] = request.headers["X-API-KEY"]
    end
  end

  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  protect_from_forgery


end
