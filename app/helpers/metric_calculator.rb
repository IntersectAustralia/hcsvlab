module MetricCalculator

  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

  REGISTERED_USERS_METRIC_NAME = "Number of registered users with role 'researcher'"
  TOTAL_RESEARCHER_VISITS_METRIC_NAME = "Total number of visits by users with role 'researcher'"
  TOTAL_DURATION_RESEARCHER_VISITS_METRIC_NAME = "Total duration of use by users with role 'researcher' (minutes)"
  TOTAL_SEARCHES_MERIC_NAME = "Total number of searches made"
  TRIPLESTORE_SEARCHES_MERIC_NAME = "Total number of triplestore searches made"
  ITEM_LISTS_METRIC_NAME = "Total number of item lists created"
  ANNOTATIONS_UPLOADED_METRIC_NAME = "Total number of uploaded annotation sets"
  TOTAL_API_CALLS_METRIC_NAME = "Total number of API calls"
  ITEM_LIST_API_CALLS_METRIC_NAME = "Total number of item list API calls"

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
    self.add_item_list_metrics(metrics)
    self.add_uploaded_annotations_metrics(metrics)
    self.add_api_metrics(metrics)
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
    self.add_latest_item_list_metric(metrics)
    self.add_latest_uploaded_annotations_metric(metrics)
    self.add_latest_api_metrics(metrics)
    return metrics.sort_by { |item| item[:metric] }
  end

  #
  # Get all metrics regarding the triplestore and return as a hash
  #
  def self.get_triplestore_metrics
    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)

    annotations = 0
    annotation_collections = 0
    triples = 0
    query = """
    PREFIX dada:<http://purl.org/dada/schema/0.2#>
    SELECT (count(?ann) as ?anncount) (count(distinct ?ac) as ?account)
    WHERE { ?ann rdf:type dada:Annotation . ?ann dada:partof ?ac . }
    """

    '''server.each_repository do |repository|
      unless repository.id == "SYSTEM"
        solutions = repository.sparql_query(query)
        solutions.each do |s|
          annotations += Integer(s[:anncount].value)
          annotation_collections += Integer(s[:account].value)
          triples += repository.triples.count
        end
      end
    end'''
    return {:annotations => annotations, :annotation_collections => annotation_collections, :triples => triples}
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
    results = UserSession.joins(:user).where('users.role_id = ?', Role.find_by_name(Role::RESEARCHER_ROLE)).group_by {|s| s.sign_in_time.end_of_week}
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
    results = UserSession.joins(:user).where('users.role_id = ?', Role.find_by_name(Role::RESEARCHER_ROLE)).group_by {|s| s.sign_in_time.end_of_week}
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
    results = UserSearch.joins(:user).where('user_searches.search_type = ?', SearchType::MAIN_SEARCH).group_by {|s| s.search_time.end_of_week}
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
    results = UserSearch.joins(:user).where('user_searches.search_type = ?', SearchType::TRIPLESTORE_SEARCH).group_by {|s| s.search_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => TRIPLESTORE_SEARCHES_MERIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_item_list_metric(metrics)
    week = Time.now.end_of_week
    value = ItemList.where('created_at < ? and created_at > ?', week, week - 1.week).count
    metrics.push( {:metric => ITEM_LISTS_METRIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_item_list_metrics(metrics)
    results = ItemList.all.group_by {|il| il.created_at.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => ITEM_LISTS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_uploaded_annotations_metric(metrics)
    week = Time.now.end_of_week
    value = UserAnnotation.where('created_at < ? and created_at > ?', week, week - 1.week).count
    metrics.push( {:metric => ANNOTATIONS_UPLOADED_METRIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_uploaded_annotations_metrics(metrics)
    results = UserAnnotation.all.group_by {|ua| ua.created_at.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => ANNOTATIONS_UPLOADED_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end


  def self.add_latest_api_metrics(metrics)
    week = Time.now.end_of_week
    # Total API calls
    value = UserApiCall.where('request_time < ? and request_time > ?', week, week - 1.week).count
    metrics.push( {:metric => TOTAL_API_CALLS_METRIC_NAME, :week_ending => week, :value => value} )
    # Total item list API calls
    value = UserApiCall.where('request_time < ? and request_time > ? and item_list = ?', week, week - 1.week, true).count
    metrics.push( {:metric => ITEM_LIST_API_CALLS_METRIC_NAME, :week_ending => week, :value => value} )
  end

  def self.add_api_metrics(metrics)
    # Total API calls
    results = UserApiCall.all.group_by {|ac| ac.request_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => TOTAL_API_CALLS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
    # Total item list API calls
    results = UserApiCall.where(:item_list => true).group_by {|ac| ac.request_time.end_of_week}
    results = Hash[results.sort]
    cumulative = 0
    results.each do |week, number|
      value = number.count
      cumulative += value
      metrics.push( {:metric => ITEM_LIST_API_CALLS_METRIC_NAME, :week_ending => week.strftime("%d/%m/%Y"), :value => value, :cumulative_value => cumulative} )
    end
  end

end
