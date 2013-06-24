When /^"(.*)" has item lists$/ do |email, table|
  user = User.find_by_email!(email)
  table.hashes.each do |attributes|
    user.item_lists.create(attributes)
  end
end