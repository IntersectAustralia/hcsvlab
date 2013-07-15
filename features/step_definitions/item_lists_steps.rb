When /^"(.*)" has item lists$/ do |email, table|
  user = User.find_by_email!(email)
  table.hashes.each do |attributes|
    user.item_lists.create(attributes)
  end
end

When /^the item list "(.*)" should have (\d+) item(?:s)?$/ do |list_name, number|
  list = ItemList.find_by_name(list_name)
  list.get_item_ids.count.should eq(number.to_i)
end

When /^the item list "(.*)" should contain ids$/ do |list_name, table|
  list = ItemList.find_by_name(list_name)
  ids = list.get_item_ids
  table.hashes.each do |attributes|
    ids.include?(attributes[:pid]).should eq(true)
  end
end

When /^the item list "(.*)" has items (.*)$/ do |list_name, ids|
  list = ItemList.find_by_name(list_name)
  list.add_items(ids.split(", "))
end

And /^I follow the delete icon for item list "(.*)"$/ do |list_name|
  list = ItemList.find_by_name(list_name)
  find("#delete_item_list_#{list.id}").click
end

When /^concordance search for "(.*)" in item list "(.*)" should show this results$/ do |term, list_name, table|
  list = ItemList.find_by_name(list_name)
  result = list.doConcordanceSearch(term)
  highlightings = result[:highlighting]
  totalMatches = table.hashes.length
  countMatches = 0
  table.hashes.each do |attributes|
    requestedMatch = attributes[:textBefore].strip()
    requestedMatch = requestedMatch + "<span class='highlighting'>#{attributes[:textHighlighted]}</span>"
    requestedMatch = requestedMatch + attributes[:textAfter].strip()

    highlightings.each do |docId, matches|
      if (!matches[:title].eql?(attributes[:documentTitle]))
        next
      end
      matches[:matches].each do |aMatch|
        retrievedMatch = aMatch[:textBefore].strip()
        retrievedMatch = retrievedMatch + aMatch[:textHighlighted].strip()
        retrievedMatch = retrievedMatch + aMatch[:textAfter].strip()

        countMatches = countMatches + 1 if requestedMatch.eql?(retrievedMatch)
      end

    end
  end
  countMatches.should eq(totalMatches)
end

When /^concordance search for "(.*)" in item list "(.*)" should show not matches found message$/ do |term, list_name|
  list = ItemList.find_by_name(list_name)
  result = list.doConcordanceSearch(term)
  result[:matching_docs].should eq(0)
end

When /^concordance search for "(.*)" in item list "(.*)" should show error$/ do |term, list_name|
  list = ItemList.find_by_name(list_name)
  result = list.doConcordanceSearch(term)
  result[:error].empty?.should eq(false)
end

When /^frequency search for "(.*)" in item list "(.*)" should show this results$/ do |term, list_name, table|
  list = ItemList.find_by_name(list_name)
  field = find_field("Facet")
  result = list.doFrequencySearch(term, field.value)

  table.hashes.each do |attributes|
    result[:status].should eq("OK")
    result[:data][attributes[:facetValue]].should_not eq (nil)
    result[:data][attributes[:facetValue]][:num_docs].to_s.should eq(attributes[:matchingDocuments])
    result[:data][attributes[:facetValue]][:num_occurrences].to_s.should eq(attributes[:termOccurrences])
  end
end

When /^frequency search for "(.*)" in item list "(.*)" should show error$/ do |term, list_name|
  list = ItemList.find_by_name(list_name)
  field = find_field("Facet")
  result = list.doFrequencySearch(term, field.value)
  result[:status].should eq("INPUT_ERROR")
end
