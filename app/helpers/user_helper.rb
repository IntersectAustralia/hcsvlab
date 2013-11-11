module UserHelper

  #
  # Calculates the total number of visits by researchers in the last week
  #
  def self::get_total_weekly_visits
    researchers = User.where(:role_id => Role.find_by_name(Role::RESEARCHER_ROLE))
    if researchers.empty?
      0
    else
      (researchers.collect {|u| (u.user_sessions.select {|session| session.last_week?}).count}).inject(:+)
    end
  end

  #
  # Calculates the average frequency of visits by researchers in the last 3 weeks
  #
  def self::get_average_frequency_visits
    researchers = User.where(:role_id => Role.find_by_name(Role::RESEARCHER_ROLE))
     if researchers.empty?
      0
    else
      week1 = (researchers.collect {|u| (u.user_sessions.select {|session| session.third_last_week?}).count}).inject(:+)
      week2 = (researchers.collect {|u| (u.user_sessions.select {|session| session.second_last_week?}).count}).inject(:+)
      week3 = (researchers.collect {|u| (u.user_sessions.select {|session| session.last_week?}).count}).inject(:+)
      ((week1+week2+week3).to_f/3.to_f).round
    end
  end

  #
  # Calculates the total duration of visits by researchers in the last week
  #
  def self::get_total_weekly_duration
    researchers = User.where(:role_id => Role.find_by_name(Role::RESEARCHER_ROLE))
    if researchers.empty?
      0
    else
      sessions = (researchers.collect {|u| (u.user_sessions.select {|session| session.last_week?})}).flatten
      seconds = !sessions.empty? ? (sessions.collect {|s| s.duration}).inject(:+) : 0
      (seconds/3600).round(2)
    end
  end

  #
  # Calculates the average duration of visits by researchers in the last 3 weeks
  #
  def self::get_average_weekly_duration
    researchers = User.where(:role_id => Role.find_by_name(Role::RESEARCHER_ROLE))
    if researchers.empty?
      0
    else
      sessions = (researchers.collect {|u| (u.user_sessions.select {|session| session.third_last_week?})}).flatten
      week1_seconds = !sessions.empty? ? (sessions.collect {|s| s.duration}).inject(:+) : 0
      sessions = (researchers.collect {|u| (u.user_sessions.select {|session| session.second_last_week?})}).flatten
      week2_seconds = !sessions.empty? ? (sessions.collect {|s| s.duration}).inject(:+) : 0
      sessions = (researchers.collect {|u| (u.user_sessions.select {|session| session.last_week?})}).flatten
      week3_seconds = !sessions.empty? ? (sessions.collect {|s| s.duration}).inject(:+) : 0
      ((week1_seconds+week2_seconds+week3_seconds)/3600/3).round(2)
    end
  end

end