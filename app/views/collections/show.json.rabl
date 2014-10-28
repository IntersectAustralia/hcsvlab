object @collection
node(:collection_url) { collection_url(@collection.name) }
node(:collection_name) { @collection.name }
node(:metadata) do
  hash = {}
  collection_show_fields(@collection).each do |field|
    hash[field.first[0]] = field.first[1].to_s
  end
  hash
end