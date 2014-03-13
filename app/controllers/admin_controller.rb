class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorizeAdmin

  def index
  end

  def metrics
    @metrics = MetricCalculator.get_latest_metrics

    @approved_researcher_count = User.approved_researchers.count
    @total_weekly_visits_count = UserHelper::get_total_weekly_visits
    @total_weekly_duration_count = UserHelper::get_total_weekly_duration
    @average_weekly_visits_count = UserHelper::get_average_frequency_visits
    @average_weekly_duration_count = UserHelper::get_average_weekly_duration
  end

  def metrics_download
    metrics = MetricCalculator.get_metrics

    file = Tempfile.new("newfile")
    file.puts metrics.first.keys.to_csv
    metrics.each do |metric|
      file.puts metric.values.join(",")
    end
    file.close
    send_file file.path, :filename => "metrics.csv", :disposition => "attachment"
  end

  private

  def authorizeAdmin
    authorize! :manage, AdminController
  end

end
