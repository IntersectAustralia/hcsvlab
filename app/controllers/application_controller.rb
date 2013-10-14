class ApplicationController < ActionController::Base

  prepend_before_filter :get_api_key
  #This will force a reload when the back button is pressed.
  before_filter :set_cache_buster
  before_filter :default_format_json

  include ErrorResponseActions
  
  rescue_from CanCan::AccessDenied, :with => :authorization_error
  rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found
  rescue_from ActiveFedora::ObjectNotFoundError, :with => :resource_not_found

  #
  # Returns application version
  #
  def version
    respond_to do |format|
      format.html {redirect_to root_path and return}

      content = render_to_string(partial: 'shared/tag', :formats => [:html], :layout => false)
      format.json { render :json => {:"API version" => content.strip}.to_json, :status => 200 }
    end
  end

  private
  def get_api_key
    params.delete(:api_key)
    if request.headers["X-API-KEY"]
      params[:api_key] = request.headers["X-API-KEY"]
    end
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def default_format_json
    if request.headers["HTTP_ACCEPT"].to_s.empty? && 
      params[:format].to_s.empty?
      request.format = "json"
    end
  end

  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  protect_from_forgery


end
