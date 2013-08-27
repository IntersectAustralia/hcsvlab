object @collection
node(:collection_url) { collection_url(@collection) }
node(:collection_name) { @collection.flat_short_name }
node(:metadata) do
  hash = {}
  collection_show_fields(@collection.id).each do |field|
    if field.first[0] == "RDF_type"
      hash[field.first[0]] = File.basename(field.first[1]).to_s
    else
      hash[field.first[0]] = field.first[1].to_s
    end
  end
  hash
end