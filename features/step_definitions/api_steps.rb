require "#{Rails.root}/lib/json-compare/orderless_json_comparer.rb"

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

When /^I make a JSON post request for (.*) with the API token for "(.*)" without JSON params$/ do |page_name, email|
  user = User.find_by_email!(email)
  post path_to(page_name), {:format => :json}, {'X-API-KEY' => user.authentication_token}
end

When /^I make a JSON put request for (.*) with the API token for "(.*)" without JSON params$/ do |page_name, email|
  user = User.find_by_email!(email)
  put path_to(page_name), {:format => :json}, {'X-API-KEY' => user.authentication_token}
end

When /^I make a JSON put request for (.*) with the API token for "(.*)" with JSON params$/ do |page_name, email, table|
  user = User.find_by_email!(email)
  hash = table.hashes.first
  hash.each do |k, v|
    begin
      hash[k] = JSON.parse(v)
    rescue
      # not a json parameter, ignore
    end
  end
  put path_to(page_name), hash.merge({:format => :json}), {'X-API-KEY' => user.authentication_token}
end

When /^I make a JSON delete request for (.*) with the API token for "(.*)"$/ do |page_name, email|
  user = User.find_by_email!(email)
  delete path_to(page_name), {:format => :json}, {'X-API-KEY' => user.authentication_token}
end

# post both the file params and the standard JSON params to the page
When /^I make a JSON multipart request for (.*) with the API token for "(.*)" with JSON and (ill-formatted )?file params$/ do |page_name, email, force_error, table|
  user = User.find_by_email!(email)
  hash = table.hashes.first
  hash.each do |k, v|
    begin
      if k == 'file' and !force_error.present?
        hash[k] = []
        file_paths = v.tr("\"", "").split(",") # this step requires file names to be enclosed in quotes and comma separated
        file_paths.each do |file_path|
          hash[k].push Rack::Test::UploadedFile.new(Rails.root.join(file_path), "application/octet-stream")
        end
      else
        hash[k] = JSON.parse(v)
      end
    rescue
      # not a json parameter, ignore
    end
  end
  post path_to(page_name), hash.merge({:format => :json}), {'X-API-KEY' => user.authentication_token}
end

# doesn't post the non-file JSON params to the page
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
    get path_to(page_name), {:format => :html, :api_key => user.authentication_token}
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
  page.response_headers['Content-Disposition'].should include("filename=\"#{PROJECT_PREFIX_NAME}_#{user.full_name.downcase.gsub(" ", "_")}_token.json\"")
  page.response_headers['Content-Disposition'].should include("attachment")
  page.source.should == "{:auth_token=>\"#{user.authentication_token}\"}"
end


# Taken from cucumber-api-steps, as the step definitions weren't getting detected

Then /^the JSON response should (not)?\s?have "([^"]*)" with the text "([^"]*)"$/ do |negative, json_path, text|
  json = JSON.parse(last_response.body)
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
  json = JSON.parse(last_response.body)
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
  json = JSON.parse(last_response.body)
  table.hashes.each do |hash|
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

  if (json.present?)
    result = OrderlessJsonCompare.get_diff(actual, expected)
    if self.respond_to?(:should)
      #actual.should == expected
      result.should be_empty, "\n expected: #{expected} \n got: #{actual} \n"
    else
      #assert_equal actual, response
      assert_true result.empty?, "\n expected: #{expected} \n got: #{actual} \n"
    end
  else
    actual = actual.force_encoding(expected.encoding)
    if self.respond_to?(:should)
      actual.should == expected
    else
      assert_equal actual, response
    end
  end
end

Then /^the (JSON )?response should have (\d+) user uploaded annotations$/ do |json, numberOfAnnotations|
  if json.present?
    actual = JSON.parse(last_response.body)
  else
    actual = last_response.body
  end
  # this regular expression matches '<UUID>/<UUID>'
  matches = actual.to_s.scan(/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/*[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/)

  if self.respond_to?(:should)
    matches.size.should == numberOfAnnotations.to_i
  else
    assert_equal matches.size, numberOfAnnotations.to_i
  end
end

Then /^the JSON response should have the following annotations properties in any order:$/ do |table|
  actual = JSON.parse(last_response.body)

  annotations = actual["#{PROJECT_PREFIX_NAME}:annotations"]

  annotations.length.should == table.hashes.length

  for x in 0..table.hashes.length-1
    expectedAnnotation = table.hashes[x]

    annotationFound = false
    y = 0
    while (!annotationFound and y < annotations.length) do
      actualAnnotation = annotations[y]
      allmatches = true
      expectedAnnotation.each_pair do |key, value|
        allmatches = allmatches & ((!value.present? & !actualAnnotation.has_key?(key)) | (value.present? and actualAnnotation[key] == value))
      end
      annotationFound = allmatches
      y = y + 1
    end

    annotationFound.should be(true), "Annotation #{expectedAnnotation.inspect} not found."

  end

end

Then(/^the file "(.+)" should (not )?exist in the directory for the api collections$/) do |file_name, not_exist|
  status = true
  status = false if not_exist.present?
  File.exist?(File.join(Rails.application.config.api_collections_location, file_name)).should be(status)
end

Then /^the file "(.+)" should (not )?exist in the directory for the collection "(.+)"$/ do |file_name, not_exist, collection_name|
  status = true
  status = false if not_exist.present?
  File.exist?(File.join(Rails.application.config.api_collections_location, collection_name, file_name)).should be(status)
end

Then /^the item "(.+)" in collection "(.+)" should (not )?exist in the database$/ do |item_name, collection_name, not_exist|
  status = true
  status = false if not_exist.present?
  Item.find_by_handle("#{collection_name}:#{item_name}").nil?.should be (!status)
end

Then /^the document "(.+)" under item "(.+)" in collection "(.+)" should (not )?exist in the database$/ do |document_base_name, item_name, collection_name, not_exist|
  status = true
  status = false if not_exist.present?
  item = Item.find_by_handle("#{collection_name}:#{item_name}")
  has_doc = false
  unless item.nil?
    item.documents.each do |document|
      has_doc = true if document.file_name == document_base_name
    end
  end
  has_doc.should be (status)
end

Then /^Sesame should (not )?contain an item with uri "(.+)" in collection "(.+)"$/ do |not_exist, item_uri, collection_name|
  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
  repository = server.repository(collection_name)
  # query the collection repo for any statements with a subject uri matching the item uri
  query = RDF::Query.new do
    pattern [RDF::URI.new(item_uri), :predicate, :object]
  end
  if not_exist.present?
    repository.query(query).count.should be 0
  else
    repository.query(query).count.should be > 0
  end
end

Then /^Sesame should (not )?contain a document with uri "(.+)" in collection "(.+)"$/ do |not_exist, document_uri, collection_name|
  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
  repository = server.repository(collection_name)
  # query the collection repo for any statements with a subject uri matching the document uri
  query = RDF::Query.new do
    pattern [RDF::URI.new(document_uri), :predicate, :object]
  end
  if not_exist.present?
    repository.query(query).count.should be 0
  else
    repository.query(query).count.should be > 0
  end
end

Then /^Sesame should (not )?contain a document with file_name "(.+)" in collection "(.+)"$/ do |not_exist, document_file_name, collection_name|
  corpus_directory = File.join(Rails.application.config.api_collections_location, collection_name)
  file_path = File.join(corpus_directory, document_file_name)
  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
  repository = server.repository(collection_name)
  # query the collection repo for any statements with a source matching the document file path
  query = RDF::Query.new do
    pattern [:subject, MetadataHelper::IDENTIFIER, "#{document_file_name}"]
    pattern [:subject, MetadataHelper::SOURCE, RDF::URI.new("file://#{file_path}")]
  end
  if not_exist.present?
    repository.query(query).count.should be 0
  else
    repository.query(query).count.should be > 0
  end
end

Then /^the owner of collection "(.+)" should be "(.+)"$/ do |collection_name, user_email|
  collection = Collection.find_by_name(collection_name)
  user = User.find_by_email(user_email)
  expect(collection.owner).to eq(user)
end