Then /^I should get a (\d+) response code$/ do |status|
  last_response.status.should == status.to_i
end

When /^I make a request for (.*) with the API token for "([^"]*)"$/ do |page_name, email|
  user = User.find_by_email!(email)
  get path_to(page_name, {:auth_token => user.authentication_token, :format => :json})
end
