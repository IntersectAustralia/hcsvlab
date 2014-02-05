Then /^I should get a (\d+) response code$/ do |status|
  last_response.status.should == status.to_i
end

When /^I make a (JSON )?request for (.*) with the API token for "(.*)"$/ do |json, page_name, email|
  user = User.find_by_email!(email)
  if json.present?
    get path_to(page_name), {:format => :json}, {'X-API-KEY' => user.authentication_token}
  else
    get path_to(page_name), {:format => :html}
  end
end

When /^I make a request with no accept header for (.*) with the API token for "(.*)"$/ do |page_name, email|
  user = User.find_by_email!(email)
  get path_to(page_name), {:format => ""}, {'X-API-KEY' => user.authentication_token}
end

When /^I make a (JSON )?request for (.*) with the API token for "(.*)" with params$/ do |json, page_name, email, table|
  user = User.find_by_email!(email)
  if json.present?
    get path_to(page_name), table.hashes.first.merge({:format => :json}), {'X-API-KEY' => user.authentication_token}
  else
    get path_to(page_name), {:format => :html}
  end
end

When /^I make a JSON post request for (.*) with the API token for "(.*)" with JSON params$/ do |page_name, email, table|
  user = User.find_by_email!(email)
  hash = table.hashes.first
  hash.each do |k, v|
    begin
      hash[k] = JSON.parse(v)
    rescue
      # not a json parameter, ignore
    end
  end
  post path_to(page_name), hash.merge({:format => :json}), {'X-API-KEY' => user.authentication_token}
end

When /^I make a JSON multipart request for (.*) with the API token for "(.*)" with JSON params$/ do |page_name, email, table|
  user = User.find_by_email!(email)
  table = table.hashes

  request = table.inject({}) do |hash, row|
    if row['Filename'].present?
      hash[row['Name']] = Rack::Test::UploadedFile.new(Rails.root.join(row['Filename']), row['Type'])
    else
      hash[row['Name']] = row['Content'].strip
    end
    hash
  end
  post path_to(page_name), request.merge({:format => :json}), {'X-API-KEY' => user.authentication_token}
end

When /^I make a (JSON )?request for (.*) with the API token for "(.*)" outside the header$/ do |json, page_name, email|
  user = User.find_by_email!(email)
  if json.present?
    get path_to(page_name), {:format => :json, :api_key => user.authentication_token}
  else
    get path_to(page_name), {:format => :html,:api_key => user.authentication_token}
  end
end

When /^I make a (JSON )?request for (.*) without an API token$/ do |json, page_name|
  if json.present?
    get path_to(page_name), {:format => :json}
  else
    get path_to(page_name), {:format => :html}
  end
end

When /^I make a (JSON )?request for (.*) with an invalid API token$/ do |json, page_name|
  if json.present?
    get path_to(page_name), {:format => :json}, {'X-API-KEY' => 'blah'}
  else
    get path_to(page_name), {:format => :html}
  end
end

When /^I make a WARC request for (.*) with the API token for "(.*)"$/ do |page_name, email|
  user = User.find_by_email!(email)
  get path_to(page_name), {:format => :warc}, {'X-API-KEY' => user.authentication_token}
end

Then /^I should see no api token$/ do
  with_scope("the api token dropdown") do
    page.should have_xpath("//li[@class='disabled']", :text => "No API Key generated")
    page.should have_xpath("//li", :text => "Generate API Key")
    page.should have_xpath("//li[@class='disabled']", :text => "Copy to Clipboard")
    page.should have_xpath("//li[@class='disabled']", :text => "Download API Key")
  end
end

Then /^I should see the api token displayed for user "(.*)"$/ do |email|
  with_scope("the api token dropdown") do
    user = User.find_by_email!(email)
    page.should have_xpath("//li[@class='disabled']", :text => user.authentication_token)
    page.should have_xpath("//li", :text => "Regenerate API Key")
    page.should have_xpath("//li", :text => "Copy to Clipboard")
    page.should have_xpath("//li", :text => "Download API Key")
  end
end

Then /^I should get the authentication token json file for "(.*)"$/ do |email|
  user = User.find_by_email!(email)
  page.response_headers['Content-Type'].should == "application/json"
  page.response_headers['Content-Disposition'].should include("filename=\"hcsvlab_#{user.full_name.downcase.gsub(" ", "_")}_token.json\"")
  page.response_headers['Content-Disposition'].should include("attachment")
  page.source.should == "{:auth_token=>\"#{user.authentication_token}\"}"
end


# Taken from cucumber-api-steps, as the step definitions weren't getting detected

Then /^the JSON response should (not)?\s?have "([^"]*)" with the text "([^"]*)"$/ do |negative, json_path, text|
  json    = JSON.parse(last_response.body)
  results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
  if self.respond_to?(:should)
    if negative.present?
      results.should_not include(text)
    else
      results.should include(text)
    end
  else
    if negative.present?
      assert !results.include?(text)
    else
      assert results.include?(text)
    end
  end
end

Then /^the JSON response should (not)?\s?have "([^"]*)"$/ do |negative, json_path|
  json    = JSON.parse(last_response.body)
  results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)

  if self.respond_to?(:should)
    if negative.present?
      results.should be_empty
    else
      results.should_not be_empty
    end
  else
    if negative.present?
      assert results.empty?
    else
      assert !results.empty?
    end
  end

end


Then /^the JSON response should (not)?\s?have$/ do |negative, table|
  table.hashes.each do |hash|
    json    = JSON.parse(last_response.body)
    json_path = hash[:json_path]
    text = hash[:text]
    results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
    if self.respond_to?(:should)
      if negative.present?
        results.should_not include(text)
      else
        results.should include(text)
      end
    else
      if negative.present?
        assert !results.include?(text)
      else
        assert results.include?(text)
      end
    end
  end
end


Then /^the JSON response should have "([^"]*)" with a length of (\d+)$/ do |json_path, length|
  json = JSON.parse(last_response.body)
  results = JsonPath.new(json_path).on(json)
  if self.respond_to?(:should)
    results.length.should == length.to_i
  else
    assert_equal length.to_i, results.length
  end
end

Then /^show me the response$/ do
  if last_response.headers['Content-Type'] =~ /json/
    json_response = JSON.parse(last_response.body)
    puts last_response.body

    puts JSON.pretty_generate(json_response)
  elsif last_response.headers['Content-Type'] =~ /xml/
    puts Nokogiri::XML(last_response.body)
  else
    puts last_response.headers
    puts last_response.body
  end
end

Then /^the (JSON )?response should be:$/ do |json, input|
  if json.present?
    expected = JSON.parse(input)
    actual = JSON.parse(last_response.body)
  else
    expected = input
    actual = last_response.body
  end
  if self.respond_to?(:should)
    actual.should == expected
  else
    assert_equal actual, response
  end
end
