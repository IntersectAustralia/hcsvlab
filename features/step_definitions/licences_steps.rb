And /^I choose the (\d+)(?:|st|nd|rd|th) Collection in the list$/ do |position|
  check("checkbox_collection_#{position.to_i-1}")
end

And /^The Collection Lists table should have$/ do |table|
  page.find("#collection_lists")
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

And /^The Collection table should have$/ do |table|
  page.find("#collections")
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




