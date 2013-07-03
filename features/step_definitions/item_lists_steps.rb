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

