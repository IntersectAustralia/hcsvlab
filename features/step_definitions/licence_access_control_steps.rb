Given /^Collections ownership is$/ do |table|
  # table is a | cooee      | data_owner@intersect.org.au |
  table.hashes.each_with_index do |row|
    collection = Collection.find_by_name(row[:collection])
    user = User.find_by_email(row[:owner_email])

    collection.owner = user
    collection.save
    user.add_agreement_to_collection(collection, UserLicenceAgreement::EDIT_ACCESS_TYPE)

  end
end

Then /^I should see only the following collections displayed in the facet menu$/ do |table|
  collectionInFacet = page.all(:xpath, "//div[@id='facets']//div[@class='facet_limit blacklight-collection_name_facet']//a[@class='facet_select']", visible: false)
  collectionsName = collectionInFacet.map { |c| c.text }
  collectionsName.length.should eq table.hashes.length
  table.hashes.each do |row|
    collectionsName.should include(row[:collection])
  end
end

Given /^"(.*)" has "(.*)" access to collection "(.*)"$/ do |userEmail, accessType, collectionName|
  user = User.find_by_email(userEmail)
  collection = Collection.find_by_name(collectionName)
  case accessType.downcase
    when "discover"
      user.add_agreement_to_collection(collection, UserLicenceAgreement::DISCOVER_ACCESS_TYPE)
    when "read"
      user.add_agreement_to_collection(collection, UserLicenceAgreement::READ_ACCESS_TYPE)
    when "edit"
      user.add_agreement_to_collection(collection, UserLicenceAgreement::EDIT_ACCESS_TYPE)
  end
  user.save
end