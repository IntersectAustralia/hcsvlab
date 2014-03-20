object false

data = []
node(:own) do
  @userItemLists.each do |itemList|
      hash = {}
      hash[:name] = itemList.name
      hash[:item_list_url] = item_list_url(itemList)
      hash[:num_items] = itemList.get_item_handles.size
      hash[:shared] = itemList.shared

      data << hash.clone
    end
    data
end

data2 = []
node(:shared) do
  @sharedItemLists.each do |itemList|
      hash = {}
      hash[:name] = itemList.name
      hash[:item_list_url] = item_list_url(itemList)
      hash[:num_items] = itemList.get_item_handles.size
      hash[:shared] = itemList.shared

      data2 << hash.clone
    end
    data2
end
