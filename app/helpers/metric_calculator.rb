module MetricCalculator

  REGISTERED_USERS_METRIC_NAME = "Number of registered users with role 'researcher'"
  TOTAL_RESEARCHER_VISITS_METRIC_NAME = "Total number of visits by users with role 'researcher'"
  TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME = "Total duration of use by users with role 'researcher' (minutes)"

  #
  # 
  #
  def self.get_metrics
    metrics = []
    self.add_registered_users_metrics(metrics)
    self.add_total_researcher_visits_metrics(metrics)
    self.add_total_duration_researcher_visits_metrics(metrics)
    return metrics.sort_by { |item| [item[:week_ending], item[:metric]] }.reverse!
  end


  def self.add_registered_users_metrics(metrics)
    week = User.order(:created_at).first.created_at.end_of_week

    cumulative = 0
    while week < Date.today + 1.week
      value = User.where('created_at < ? and created_at > ? and role_id = ?', week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE)).count
      cumulative += value
      metrics.push( {:metric => REGISTERED_USERS_METRIC_NAME, :week_ending => week, :value => value, :cumulative => cumulative} )
      week += 1.week
    end
  end

  def self.add_total_researcher_visits_metrics(metrics)
    week = UserSession.order(:sign_in_time).first.sign_in_time.end_of_week

    cumulative = 0
    while week < Date.today + 1.week
      value = UserSession.joins(:user).where('user_sessions.sign_in_time < ? and user_sessions.sign_in_time > ? and users.role_id = ?', 
        week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE)).count
      cumulative += value
      metrics.push( {:metric => TOTAL_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week, :value => value, :cumulative => cumulative} )
      week += 1.week
    end
  end

  def self.add_total_duration_researcher_visits_metrics(metrics)
    week = UserSession.order(:sign_in_time).first.sign_in_time.end_of_week

    cumulative = 0
    while week < Date.today + 1.week
      sessions = UserSession.joins(:user).where('user_sessions.sign_in_time < ? and user_sessions.sign_in_time > ? and users.role_id = ?', 
        week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE))
      value = 0
      sessions.each {|s| value += s.duration}
      cumulative += value
      metrics.push( {:metric => TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week, :value => (value/60).round(2), :cumulative => (cumulative/60).round(2)} )
      week += 1.week
    end
  end

end
