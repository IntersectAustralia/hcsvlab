class ApplicationController < ActionController::Base
  rescue_from DeviseAafRcAuthenticatable::AafRcException do |exception|
    render :text => exception, :status => 500
  end

  prepend_before_filter :get_api_key
  prepend_before_filter :retrieve_aaf_credentials
  #This will force a reload when the back button is pressed.
  before_filter :set_cache_buster
  before_filter :default_format_json
  before_filter :api_check

  include ErrorResponseActions
  
  rescue_from CanCan::AccessDenied, :with => :authorization_error
  rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found
  rescue_from MultiJson::LoadError, :with => :json_error

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

  def metrics
    @metrics = MetricCalculator.get_latest_metrics

    @triplestore_metrics = MetricCalculator.get_triplestore_metrics
    @approved_researcher_count = User.approved_researchers.count
    @total_weekly_visits_count = UserHelper::get_total_weekly_visits
    @total_weekly_duration_count = UserHelper::get_total_weekly_duration
    @average_weekly_visits_count = UserHelper::get_average_frequency_visits
    @average_weekly_duration_count = UserHelper::get_average_weekly_duration
  end

  def metrics_download
    metrics = MetricCalculator.get_metrics

    file = Tempfile.new("newfile")
    unless metrics.empty?
      file.puts metrics.first.keys.to_csv
      metrics.each do |metric|
        file.puts metric.values.join(",")
      end
    end
    file.close
    send_file file.path, :filename => "metrics.csv", :disposition => "attachment"
  end

  private
  def get_api_key
    params.delete(:api_key)
    if request.headers["X-API-KEY"]
      params[:api_key] = request.headers["X-API-KEY"]
    end
  end

  def retrieve_aaf_credentials
    @aaf_credentials = session['attributes'] || {}
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

  def api_check
    if request.format == "json"
      call = UserApiCall.new(:request_time => Time.now)
      call.item_list = params[:controller] == "item_lists"
      call.user = current_user
      call.save
    end
  end

  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  protect_from_forgery


end
