object false

data = []
node(:own) do
  @user_item_lists.each do |itemList|
      hash = {}
      hash[:name] = itemList.name
      hash[:item_list_url] = item_list_url(itemList)
      hash[:num_items] = itemList.items_in_item_lists.count
      hash[:shared] = itemList.shared

      data << hash.clone
    end
    data
end

data2 = []
node(:shared) do
  @shared_item_lists.each do |itemList|
      hash = {}
      hash[:name] = itemList.name
      hash[:item_list_url] = item_list_url(itemList)
      hash[:num_items] = itemList.items_in_item_lists.count
      hash[:shared] = itemList.shared

      data2 << hash.clone
    end
    data2
end
