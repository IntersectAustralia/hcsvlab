And /^I choose the (\d+)(?:|st|nd|rd|th) Collection in the list$/ do |position|
  check("checkbox_collection_#{position.to_i-1}")
end

And /^The Collection Lists table should have$/ do |table|
  patiently do
    table.hashes.each_with_index do |row, index|
      page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='name']/a", :text => row[:collection_list])
      page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='owner']", :text => row[:owner])
      page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='licence']//button", :text => row[:licence])
      if row[:licence_terms].empty?
        page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='terms']", :text => '')
      else
        page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='terms']/a", :text => row[:licence_terms])
      end
      Capybara.ignore_hidden_elements = false
      page.should have_xpath("//h3[@id='myModalLabel']", text: row[:collection_list])
      if row[:collections]

        row[:collections].split(",").each do |collection|
          page.should have_xpath("//table[@id='collection_lists']//tr[#{index+1}]//td[@class='name']//div[@id='collection_list_detail_content']//td[@class='collection']", :text => collection)

        end

      end
      Capybara.ignore_hidden_elements = true

    end
  end
end

And /^The Collection table should have$/ do |table|
  patiently do
    table.hashes.each_with_index do |row, index|
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='name']", :text => row[:collection])

      if row[:licence].empty?
        page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='licence']", :text => row[:licence])
      else
        page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='licence']//button", :text => row[:licence])
      end

      if row[:licence_terms].empty?
        page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='terms']", :text => '')
      else
        page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='terms']/a", :text => row[:licence_terms])
      end
    end
  end
end

And /^I click Add Licence for the (\d+)(?:|st|nd|rd|th) collection$/ do |position|
  button = page.find(:xpath, "//table[@id='collections']//tr[#{position}]//td[@class='licence']//button")

  button.click
end

And /^I click Add Licence for the (\d+)(?:|st|nd|rd|th) collection list$/ do |position|
  button = page.find(:xpath, "//table[@id='collection_lists']//tr[#{position}]//td[@class='licence']//button")

  button.click
end
And /^I click on the remove icon for the (\d+)(?:|st|nd|rd|th) collection list$/ do |position|
  link = page.find(:xpath, "//table[@id='collection_lists']//tr[#{position}]//td[@class='actions']//a")

  link.click
end

And /^I click on the privacy remove icon for the (\d+)(?:|st|nd|rd|th) collection list$/ do |position|
  link = page.find(:xpath, "//table[@id='collection_lists']//tr[#{position}]//td[@class='privacy']//a")
  link.click
end

And /^I click on the privacy remove icon for the (\d+)(?:|st|nd|rd|th) collection$/ do |position|
  link = page.find(:xpath, "//table[@id='collections']//tr[#{position}]//td[@class='privacy']//a")
  link.click
end

And /^I click View Licence Terms for the (\d+)(?:|st|nd|rd|th) collection$/ do |position|
  link = page.find(:xpath, "//table[@id='collections']//tr[#{position}]//td[@class='terms']//a")

  link.click
end

Given /^User "([^"]*)" has a Collection List called "([^"]*)" containing$/ do |email, list_name, table|
  # Create the Collection List
  list = CollectionList.new
  list.name = list_name

  user = User.find_by_user_key(email)
  list.owner = user
  list.save!

  # Populate it with the collections mentioned in the table
  ids = []
  table.hashes.each_with_index do |row|
    collection = Collection.find_by_name(row[:collection])
    ids << collection.id
  end

  list.add_collections(ids)
end

Then /^the Review and Acceptance of Licence Terms table should have$/ do |table|
  # table is a | austlit    | N/A         | data_owner@intersect.org.au | Owner |         |
  patiently do
    table.hashes.each_with_index do |row, index|
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='title']", :text => row[:title])
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='collection']", :text => row[:collection])
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='owner']", :text => row[:owner])
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='state']", :text => row[:state])
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//a[@class='btn btn-mini']", :text => row[:actions]) unless row[:actions] == ""
    end
  end

end

And /^I have added a licence to (private )?Collection "([^"]*)"$/ do |priv, name|
  coll = Collection.find_by_name(name)
  coll.set_licence(Licence.first)
  coll.set_privacy(priv.present?)
end

And /^I have added a licence to (private )?Collection List "([^"]*)"$/ do |priv, name|
  list = CollectionList.find_by_name(name)
  list.set_licence(Licence.first.id)
  list.set_privacy(priv.present?)
end

And /^I click the action button in the (\d+)(?:|st|nd|rd|th) row of the "([^"]*)" table$/ do |position, table|
  button = page.find(:xpath, "//table[@id='#{table}']//tr[#{position}]//td[@class='actions']/a[@class='btn btn-mini']")
  button.click
end

And /^I click the link in the (\d+)(?:|st|nd|rd|th) column of the (\d+)(?:|st|nd|rd|th) row of the "([^"]*)" table$/ do |column, row, table|
  button = page.find(:xpath, "//table[@id='#{table}']//tr[#{row}]//td[#{column}]/a")
  button.click
end

And /^I click the button in the (\d+)(?:|st|nd|rd|th) column of the (\d+)(?:|st|nd|rd|th) row of the "([^"]*)" table$/ do |column, row, table|
  button = page.find(:xpath, "//table[@id='#{table}']//tr[#{row}]//td[#{column}]/a[@class='btn btn-mini']")
  button.click
end

And /^I click "([^"]*)" on the (\d+)(?:|st|nd|rd|th) licence dialogue$/ do |name, position|
  button = page.find(:xpath, "//div[@id='licence_preview#{position.to_i-1}']//a", :text => name)
  button.click
end

Given(/^there is a licence request for collection "(.*?)" by "(.*?)"$/) do |collection_name, email|
  coll = Collection.find_by_name(collection_name)
  user = User.find_by_user_key(email)
  req = UserLicenceRequest.new(:request_id => coll.id.to_s, :request_type => "collection", :approved => false, :owner_id => coll.owner_id)
  req.user = user
  req.save!
end

Given(/^there is a licence request for collection list "(.*?)" by "(.*?)"$/) do |collection_name, email|
  coll = CollectionList.find_by_name(collection_name)
  user = User.find_by_user_key(email)
  req = UserLicenceRequest.new(:request_id => coll.id.to_s, :request_type => "collection_list", :approved => false, :owner_id => coll.owner_id)
  req.user = user
  req.save!
end

And /^I click "([^"]*)" in the add to collection list dropdown$/ do |name|
  within('#create_list_drop_down') do
    click_on(name)
  end
end

Given(/^I have licence "(.*?)" with id (\d+)$/) do |name, id|
  FactoryGirl.create(:licence, name: name, id: id)
end

Then(/^collection "(.*?)" should have licence "(.*?)"$/) do |collection, licence|
  coll = Collection.find_by_name(collection)
  coll.licence.name.should eq(licence)
end