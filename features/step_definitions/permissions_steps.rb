Then /^I should get the following security outcomes$/ do |table|
  table.hashes.each do |hash|
    page_to_visit = hash[:page]
    outcome = hash[:outcome]
    message = hash[:message]
    visit path_to(page_to_visit)
    if outcome == "error"
      page.should have_content(message)
      current_path = URI.parse(current_url).path
      current_path.should == path_to("the home page")
    else
      current_path = URI.parse(current_url).path
      current_path.should == path_to(page_to_visit)
    end

  end
end

Given /^I have the usual roles and permissions$/ do
  Role.create!(:name => Role::SUPERUSER_ROLE)
  Role.create!(:name => Role::RESEARCHER_ROLE)
  Role.create!(:name => Role::DATA_OWNER_ROLE)
end

