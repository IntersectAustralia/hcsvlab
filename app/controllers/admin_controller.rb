require 'will_paginate/array'

class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorizeAdmin

  def index
  end

  def metrics
    metrics = MetricCalculator.get_metrics
    @metrics = metrics.paginate(:page => params[:page], :per_page => 10)

    @approved_researcher_count = User.approved_researchers.count
    @total_weekly_visits_count = UserHelper::get_total_weekly_visits
    @total_weekly_duration_count = UserHelper::get_total_weekly_duration
    @average_weekly_visits_count = UserHelper::get_average_frequency_visits
    @average_weekly_duration_count = UserHelper::get_average_weekly_duration
  end

  private

  def authorizeAdmin
    authorize! :manage, AdminController
  end

end
