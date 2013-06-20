Then /^I should get a (\d+) response code$/ do |status|
  last_response.status.should == status.to_i
end

When /^I make a request for (.*) with the API token for "([^"]*)"$/ do |page_name, email|
  user = User.find_by_email!(email)
  get path_to(page_name, {:auth_token => user.authentication_token, :format => :json})
end

Then /^I should see no api token$/ do
  with_scope("the api token dropdown") do
    page.should have_xpath("//li[@class='disabled']", :text => "No token generated")
    page.should have_xpath("//li", :text => "Generate Token")
    page.should have_xpath("//li[@class='disabled']", :text => "Copy to Clipboard")
    page.should have_xpath("//li[@class='disabled']", :text => "Download Token")
  end
end

Then /^I should see the api token displayed for user "([^"]*)"$/ do |email|
  with_scope("the api token dropdown") do
    user = User.find_by_email!(email)
    page.should have_xpath("//li[@class='disabled']", :text => user.authentication_token)
    page.should have_xpath("//li", :text => "Regenerate Token")
    page.should have_xpath("//li", :text => "Copy to Clipboard")
    page.should have_xpath("//li", :text => "Download Token")
  end
end

Then /^I should get the authentication token json file for "([^"]*)"$/ do |email|
  user = User.find_by_email!(email)
  page.response_headers['Content-Type'].should == "application/json"
  page.response_headers['Content-Disposition'].should include("filename=\"hcsvlab_#{user.full_name.downcase.gsub(" ", "_")}_token.json\"")
  page.response_headers['Content-Disposition'].should include("attachment")
  page.source.should == "{:auth_token=>\"#{user.authentication_token}\"}"
end