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
    end
  end
end

And /^The Collection table should have$/ do |table|
  patiently do
    table.hashes.each_with_index do |row, index|
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='name']", :text => row[:collection])

      if (row[:collection_list].empty?)
        page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='collection']", :text => '')
      else
        page.should have_xpath("//table[@id='collections']//tr[#{index+1} and @class='groupedCollection']//td[@class='collection']/div[contains(., '#{row[:collection_list]}')]")
      end

      if(row[:licence].empty? or !row[:collection_list].empty?)
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
  button = page.find(:xpath,"//table[@id='collections']//tr[#{position}]//td[@class='licence']//button")

  button.click
end

And /^I click Add Licence for the (\d+)(?:|st|nd|rd|th) collection list$/ do |position|
  button = page.find(:xpath,"//table[@id='collection_lists']//tr[#{position}]//td[@class='licence']//button")

  button.click
end
And /^I click on the remove icon for the (\d+)(?:|st|nd|rd|th) collection list$/ do |position|
  link = page.find(:xpath,"//table[@id='collection_lists']//tr[#{position}]//td[@class='actions']//a")

  link.click
end

And /^I click View Licence Terms for the (\d+)(?:|st|nd|rd|th) collection$/ do |position|
  link = page.find(:xpath,"//table[@id='collections']//tr[#{position}]//td[@class='terms']//a")

  link.click
end

Given /^User "([^"]*)" has a Collection List called "([^"]*)" containing$/ do |email, list_name, table|
  # Create the Collection List
  list = CollectionList.new()
  list.name = list_name

  user = User.find_by_user_key(email)
  list.ownerEmail = email
  list.ownerId    = user.id.to_s
  list.save!

  # Populate it with the collections mentioned in the table
  ids = []
  table.hashes.each_with_index do |row|
    collection = Collection.find_by_short_name(row[:collection]).to_a.first
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
      page.should have_xpath("//table[@id='collections']//tr[#{index+1}]//td[@class='action']", :text => row[:actions]) unless row[:actions] == ""
    end
  end

end

And /^I have added a licence to Collection "([^"]*)"$/ do |name|
  coll = Collection.find_by_short_name(name).to_a.first
  coll.setLicence(Licence.first.id)
end

And /^I have added a licence to Collection List "([^"]*)"$/ do |name|
  list = CollectionList.find_by_name(name)[0]
  list.setLicence(Licence.first.id)
end

Given /^Collection ownership is$/ do |table|
  # table is a | cooee      | data_owner@intersect.org.au |
  table.hashes.each do |row|
    coll = Collection.find_by_short_name(row[:collection])[0]
    user = User.find_by_user_key(row[:ownerEmail])

    coll.data_owner = user
    coll.save
  end
end