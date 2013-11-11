class UserSession < ActiveRecord::Base

  belongs_to :user

  attr_accessible :sign_in_time, :sign_out_time

  def duration
  	self.sign_out_time - self.sign_in_time
  end

  def last_week?
  	self.sign_in_time >= 1.week.ago
  end

  def second_last_week?
  	self.sign_in_time >= 2.weeks.ago and self.sign_in_time < 1.weeks.ago
  end

  def third_last_week?
  	self.sign_in_time >= 3.weeks.ago and self.sign_in_time < 2.weeks.ago
  end
end