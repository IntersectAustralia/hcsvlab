module MetricCalculator

  REGISTERED_USERS_METRIC_NAME = "Number of registered users with role 'researcher'"
  TOTAL_RESEARCHER_VISITS_METRIC_NAME = "Total number of visits by users with role 'researcher'"
  TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME = "Total duration of use by users with role 'researcher' (minutes)"
  TOTAL_SEARCHES_MERIC_NAME = "Total number of searches made"
  TRIPLESTORE_SEARCHES_MERIC_NAME = "Total number of triplestore searches made"

  #
  # get an array containing all the metrics
  #
  def self.get_metrics
    metrics = []
    self.add_registered_users_metrics(metrics)
    self.add_total_researcher_visits_metrics(metrics)
    self.add_total_duration_researcher_visits_metrics(metrics)
    self.add_total_searches_metrics(metrics)
    self.add_triplestore_searches_metrics(metrics)
    return metrics
  end

  #
  # get an array containing all the metrics from the past week
  #
  def self.get_latest_metrics
    metrics = []
    self.add_latest_registered_users_metric(metrics)
    self.add_latest_total_researcher_visits_metric(metrics)
    self.add_latest_total_duration_researcher_visits_metric(metrics)
    self.add_latest_total_searches_metric(metrics)
    self.add_latest_triplestore_searches_metric(metrics)
    return metrics.sort_by { |item| item[:metric] }
  end


  def self.add_latest_registered_users_metric(metrics)
    week = Time.now.end_of_week
    value = User.where('created_at < ? and created_at > ? and role_id = ?', week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE)).count
    metrics.push( {:metric => REGISTERED_USERS_METRIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_registered_users_metrics(metrics)
    results = User.where('role_id = ?', Role.find_by_name(Role::RESEARCHER_ROLE)).group_by {|u| u.created_at.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => REGISTERED_USERS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_total_researcher_visits_metric(metrics)
    week = Time.now.end_of_week
    value = UserSession.joins(:user).where('user_sessions.sign_in_time < ? and user_sessions.sign_in_time > ? and users.role_id = ?', 
      week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE)).count
    metrics.push( {:metric => TOTAL_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_total_researcher_visits_metrics(metrics)
    results = UserSession.joins(:user).where('users.role_id = ?', Role.find_by_name(Role::RESEARCHER_ROLE)).group_by {|u| u.sign_in_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => TOTAL_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_total_duration_researcher_visits_metric(metrics)
    week = Time.now.end_of_week
    sessions = UserSession.joins(:user).where('user_sessions.sign_in_time < ? and user_sessions.sign_in_time > ? and users.role_id = ?', 
      week.utc, week.utc - 1.week, Role.find_by_name(Role::RESEARCHER_ROLE))
    value = 0
    sessions.each {|s| value += s.duration}
    metrics.push( {:metric => TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week, :value => (value/60).round(2)} )
  end

  def self.add_total_duration_researcher_visits_metrics(metrics)
    results = UserSession.joins(:user).where('users.role_id = ?', Role.find_by_name(Role::RESEARCHER_ROLE)).group_by {|u| u.sign_in_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = 0
      number.each { |session| value += session.duration }
      cumulative += value
      metrics.push( {:metric => TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => (value/60).round(2), :cumulative_value => (cumulative/60).round(2)} )
    end
  end


  def self.add_latest_total_searches_metric(metrics)
    week = Time.now.end_of_week
    value = UserSearch.joins(:user).where('user_searches.search_time < ? and user_searches.search_time > ? and user_searches.search_type = ?',
      week.utc, week.utc - 1.week, SearchType::MAIN_SEARCH).count
    metrics.push( {:metric => TOTAL_SEARCHES_MERIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_total_searches_metrics(metrics)
    results = UserSearch.joins(:user).where('user_searches.search_type = ?', SearchType::MAIN_SEARCH).group_by {|u| u.search_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => TOTAL_SEARCHES_MERIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_triplestore_searches_metric(metrics)
    week = Time.now.end_of_week
    value = UserSearch.joins(:user).where('user_searches.search_time < ? and user_searches.search_time > ? and user_searches.search_type = ?',
      week.utc, week.utc - 1.week, SearchType::TRIPLESTORE_SEARCH).count
    metrics.push( {:metric => TRIPLESTORE_SEARCHES_MERIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_triplestore_searches_metrics(metrics)
    results = UserSearch.joins(:user).where('user_searches.search_type = ?', SearchType::TRIPLESTORE_SEARCH).group_by {|u| u.search_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => TRIPLESTORE_SEARCHES_MERIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end

end
