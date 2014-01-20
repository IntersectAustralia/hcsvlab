object @itemInfo
if @itemInfo.nil?
  node(:error) { "Item does not exist with given id" }
else
  node(:@context) { annotation_context_url }

  node(:catalog_url) { @itemInfo.catalog_url }

  node(:metadata) { @itemInfo.metadata }

  node(:primary_text_url) { @itemInfo.primary_text_url }

  unless @itemInfo.annotations_url.nil?
  	node(:annotations_url) { @itemInfo.annotations_url }
  end

  node(:documents) { @itemInfo.documents }

end