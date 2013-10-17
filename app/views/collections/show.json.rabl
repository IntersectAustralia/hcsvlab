object @collection
node(:collection_url) { collection_url(@collection) }
node(:collection_name) { @collection.flat_short_name }
node(:metadata) do
  hash = {}
  collection_show_fields(@collection.id).each do |field|
    hash[field.first[0]] = field.first[1].to_s
  end
  hash
end