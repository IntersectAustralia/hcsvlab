Then /^I should get a (\d+) response code$/ do |status|
  last_response.status.should == status.to_i
end

When /^I make a (JSON )?request for (.*) with the API token for "(.*)"$/ do |json, page_name, email|
  user = User.find_by_email!(email)
  options = {:auth_token => user.authentication_token}
  options.merge!(:format => :json) if json.present?
  get path_to(page_name, options)
end

When /^I make a (JSON )?request for (.*) without an API token$/ do |json, page_name|
  options = {}
  options.merge!(:format => :json) if json.present?
  get path_to(page_name, options)
end

When /^I make a (JSON )?request for (.*) with an invalid API token$/ do |json, page_name|
  options = {:auth_token => 'blah'}
  options.merge!(:format => :json) if json.present?
  get path_to(page_name, options)
end

Then /^I should see no api token$/ do
  with_scope("the api token dropdown") do
    page.should have_xpath("//li[@class='disabled']", :text => "No token generated")
    page.should have_xpath("//li", :text => "Generate Token")
    page.should have_xpath("//li[@class='disabled']", :text => "Copy to Clipboard")
    page.should have_xpath("//li[@class='disabled']", :text => "Download Token")
  end
end

Then /^I should see the api token displayed for user "(.*)"$/ do |email|
  with_scope("the api token dropdown") do
    user = User.find_by_email!(email)
    page.should have_xpath("//li[@class='disabled']", :text => user.authentication_token)
    page.should have_xpath("//li", :text => "Regenerate Token")
    page.should have_xpath("//li", :text => "Copy to Clipboard")
    page.should have_xpath("//li", :text => "Download Token")
  end
end

Then /^I should get the authentication token json file for "(.*)"$/ do |email|
  user = User.find_by_email!(email)
  page.response_headers['Content-Type'].should == "application/json"
  page.response_headers['Content-Disposition'].should include("filename=\"hcsvlab_#{user.full_name.downcase.gsub(" ", "_")}_token.json\"")
  page.response_headers['Content-Disposition'].should include("attachment")
  page.source.should == "{:auth_token=>\"#{user.authentication_token}\"}"
end

When /^I should get a JSON response with$/ do |table|
  actual = JSON.parse(last_response.body)
  actual.size.should eq(table.hashes.size)
  count = 0
  table.hashes.each do |attributes|
    actual[count]["filename"].should eq(attributes["filename"])
    count += 1
  end
end