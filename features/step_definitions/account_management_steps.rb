Given /^I have access requests$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:user, hash.merge(:status => 'U'))
  end
end

Given /^I have users$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:user, hash.merge(:status => 'A'))
  end
end

Given /^I have roles$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:role, hash)
  end
end

And /^I have role "([^"]*)"$/ do |name|
  FactoryGirl.create(:role, :name => name)
end

Given /^"([^"]*)" has role "([^"]*)"$/ do |email, role|
  user = User.where(:email => email).first
  role = Role.where(:name => role).first
  user.role = role
  user.save!(:validate => false)
end

When /^I follow "Approve" for "([^"]*)"$/ do |email|
  user = User.where(:email => email).first
  click_link("approve_#{user.id}")
end

When /^I follow "Reject" for "([^"]*)"$/ do |email|
  user = User.where(:email => email).first
  click_link("reject_#{user.id}")
end

When /^I follow "Reject as Spam" for "([^"]*)"$/ do |email|
  user = User.where(:email => email).first
  click_link("reject_as_spam_#{user.id}")
end

When /^I follow "View Details" for "([^"]*)"$/ do |email|
  user = User.where(:email => email).first
  click_link("view_#{user.id}")
end

When /^I follow "Edit role" for "([^"]*)"$/ do |email|
  user = User.where(:email => email).first
  click_link("edit_role_#{user.id}")
end

Given /^"([^"]*)" is deactivated$/ do |email|
  user = User.where(:email => email).first
  user.deactivate
end

Given /^"([^"]*)" is pending approval$/ do |email|
  user = User.where(:email => email).first
  user.status = "U"
  user.save!
end

Given /^"([^"]*)" is rejected as spam$/ do |email|
  user = User.where(:email => email).first
  user.reject_access_request
end

Given /^"([^"]*)" has an api token$/ do |email|
  user = User.where(:email => email).first
  user.reset_authentication_token!
end

Given(/^"(.*?)" has the following past sessions$/) do |email, table|
  user = User.find_by_email(email)
  table.hashes.each do |row|
    days_ago = row[:sign_in_time].scan(/\d/).join('')
    s = UserSession.new(:sign_in_time => days_ago.to_i.days.ago)
    s.sign_out_time = s.sign_in_time + row[:duration_in_minutes].to_i.minutes
    s.user = user
    s.save
  end
end