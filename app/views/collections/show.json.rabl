object @collection
node(:@context) { annotation_context_url }
node(:"#{PROJECT_PREFIX_NAME}:collection_url") { collection_url(@collection.name) }
node(:"#{PROJECT_PREFIX_NAME}:metadata") do
  hash = {}
  hash["#{PROJECT_PREFIX_NAME}:collection_name"] = @collection.name
  @collection.rdf_graph.statements.each_with_index do |triple, index|
    if triple.predicate.qname
      key = triple.predicate.qname.join(":")
    else
      key = MetadataHelper::rdf_form(triple.predicate)
    end
    hash[key] = triple.object.to_s
  end
  hash["#{PROJECT_PREFIX_NAME}:sparql_endpoint"] = catalog_sparqlQuery_url(@collection.name)
  hash
end