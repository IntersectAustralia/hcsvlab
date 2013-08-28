Then /^I should get the following security outcomes$/ do |table|
  table.hashes.each do |hash|
    page_to_visit = hash[:page]
    outcome = hash[:outcome]
    message = hash[:message]
    set_html_request
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

Given /^I have user "(.*)" with the following groups$/ do |userMail, table|
  user = User.find_by_email(userMail)
  table.hashes.each do |row|
    col = Collection.find_by_short_name(row[:collectionName]).first

    if (col.nil?)
      col = Collection.new
      col.short_name = row[:collectionName]
      col.uri = row[:collectionName]
      col.save
    end

    # Id the collection has no licence set, we will create one
    if (col.licence.nil?)
      l1 = Licence.new
      l1.name = "Licence 1"
      l1.text = "Text Licence 1"
      l1.ownerId = user.id.to_s
      l1.ownerEmail = user.email.to_s
      l1.save

      col.licence = l1
      col.save
    end

    user.add_agreement_to_collection(col, row[:accessType])
  end
end
