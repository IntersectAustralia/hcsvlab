Given /^Collections ownership is$/ do |table|
  table.hashes.each_with_index do |row|
    collection = Collection.find_by_short_name(row[:collection]).to_a.first

    collection.private_data_owner = row[:ownerEmail]
    collection.save

    user = User.find_by_email(row[:ownerEmail])
    if (!user.nil?)
      user.add_agreement_to_collection(collection, UserLicenceAgreement::EDIT_ACCESS_TYPE)
    end

    #By now this is not going to work since "our" SOLR core is not being updated
    #collection.items.each do |aItem|
    #  aItem.set_discover_users([row[:ownerEmail]], [])
    #  aItem.set_read_users([row[:ownerEmail]], [])
    #  aItem.set_edit_users([row[:ownerEmail]], [])
    #  aItem.save
    #end
  end
end

Then /^I should see only the following collections displayed in the facet menu$/ do |table|
  collectionInFacet = page.all(:xpath, "//div[@id='facets']//div[@class='facet_limit blacklight-hcsvlab_collection']//a[@class='facet_select']", visible: false)
  collectionsName = collectionInFacet.map{|c| c.text}
  collectionsName.length.should eq table.hashes.length
  table.hashes.each do |row|
    collectionsName.should include(row[:collection])
  end
end

Given /^"(.*)" has "(.*)" access to collection "(.*)"$/ do |userEmail, accessType, collectionName|
  user = User.find_by_email(userEmail)
  collection = Collection.find_by_short_name(collectionName).to_a.first
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