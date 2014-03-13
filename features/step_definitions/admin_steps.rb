Then(/^I should get a CSV file called "(.*?)" with the following metrics:$/) do |filename, contents|
  page.response_headers['Content-Disposition'].should include(filename)
  page.response_headers['Content-Disposition'].should include("attachment")

  contents.each_line do |line|
    page.body.should include(line.rstrip)
  end
end