require Rails.root.join('lib/api/response_error')

module RequestValidator

  # Validates JSON-LD metadata
  def validate_jsonld(graph)
    raise ResponseError.new(400), "Invalid metadata" if graph.blank?
    rdf_graph = RDF::Graph.new << JSON::LD::API.toRDF(graph)
    validate_rdf_graph(rdf_graph)
  end

  # Validates RDF metadata
  def validate_rdf_graph(graph)
    raise ResponseError.new(400), "Invalid metadata" if graph.invalid?
  end

  # Validates the collection exists and the user is authorised to modify it
  def validate_collection(collection_id, api_key)
    collection = validate_collection_exists(Collection.sanitise_name(collection_id))
    if api_key != User.find(collection.owner_id).authentication_token
      raise ResponseError.new(403), "User is unauthorised" # Authorise by comparing api key sent with collection owner's api key
    end
    collection
  end

  # Validates a collection with a matching name exists
  def validate_collection_exists(collection_id)
    collection = Collection.find_by_name(collection_id)
    raise ResponseError.new(404), "Requested collection not found" if collection.nil?
    collection
  end

  # Validates that the given item name is not already in use by an existing item in the given collection
  # Returns a sanitised copy of the item name
  def validate_item_name_unique(collection, name)
    item_name = Item.sanitise_name(name)
    if collection.items.find_by_handle("#{collection.name}:#{item_name}").present?
      raise ResponseError.new(400), "An item with the name '#{item_name}' already exists in this collection"
    end
    item_name
  end

  # Validates an item with a matching handle exists under the collection
  def validate_item_exists (collection, item_id)
    item = collection.items.find_by_handle("#{collection.name}:#{item_id}")
    raise ResponseError.new(404), "Requested item not found" if item.nil?
    item
  end

  def validate_document_exists (item, document_name)
    document = item.documents.find_by_file_name(document_name)
    raise ResponseError.new(404), "Requested document not found" if document.nil?
    document
  end

  # Validates the request on the add items api call
  def validate_add_items_request(collection, corpus_dir, items_param, files_param)
    validate_items(items_param, collection, corpus_dir)
    validate_files(files_param, collection, corpus_dir)
    validate_document_identifiers(get_document_identifiers(files_param, items_param))
  end

  # Validates the request on the add document api call
  def validate_add_document_request(corpus_dir, collection, document_metadata, document_filename, document_content, uploaded_file)
    raise ResponseError.new(400), "Document identifier missing" if document_filename.nil?
    validate_uploaded_file(uploaded_file, collection, corpus_dir) unless uploaded_file.nil?
    unless document_content.nil?
      raise ResponseError.new(400), "Document content missing" if document_content.blank?
      validate_new_document_file(corpus_dir, document_filename, collection)
    end
  end

  private

  # Iterates over the uploaded files and JSON document content and returns a list of document identifiers/filenames
  def get_document_identifiers(uploaded_files, items_metadata)
    document_identifiers = []
    items_metadata.each do |item|
      unless item["documents"].nil?
        item["documents"].each do |document|
          document_identifiers.push(document["identifier"])
        end
      end
    end
    uploaded_files.each do |uploaded_file|
      document_identifiers.push(uploaded_file.original_filename)
    end
    document_identifiers
  end

  # Validates that each of the document identifiers are unique
  def validate_document_identifiers(document_identifiers)
    duplicate_id = document_identifiers.detect{|identifier| document_identifiers.count(identifier) > 1}
    raise ResponseError.new(412), "The identifier #{duplicate_id} is used for multiple documents" unless duplicate_id.nil?
  end

  # Iterates over the item metadata and returns an array of all item dc:identifiers
  def get_item_identifiers(item_json_ld)
    dc_identifiers = []
    item_json_ld["@graph"].each do |node|
      is_ausnc_doc = node["@type"] == "ausnc:document" || node["@type"] == MetadataHelper::DOCUMENT.to_s
      is_foaf_doc = node["@type"] == "foaf:Document" || node["@type"] == MetadataHelper::FOAF_DOCUMENT.to_s
      is_doc = is_ausnc_doc || is_foaf_doc
      unless is_doc
        ['dc:identifier', 'dcterms:identifier', MetadataHelper::IDENTIFIER.to_s].each do |dc_identifier|
          dc_identifiers.push(node[dc_identifier]) if node.has_key?(dc_identifier)
        end
      end
    end
    dc_identifiers
  end

  # Validates the item identifier
  def validate_item_identifier(item_identifier, collection_name)
    raise ResponseError.new(400), "There is an item with a missing or blank identifier" if item_identifier.blank?
    existing_item = Item.find_by_handle("#{collection_name}:#{item_identifier}")
    raise ResponseError.new(412), "The item #{item_identifier} already exists in the collection #{collection_name}" if existing_item
  end

  # Validates the metadata for each of the items
  def validate_items(items_json, collection, corpus_dir)
    raise ResponseError.new(400), "JSON-LD formatted item metadata must be sent with the api request" if items_json.blank?
    items_json.each do |item|
      validate_item(item, collection, corpus_dir)
    end
  end

  # Validates the item doesn't exist in the collection and validates any document metadata with the item
  def validate_item(item_json, collection, corpus_dir)
    item_identifiers = get_item_identifiers(item_json["metadata"])
    item_identifiers.each do |item_identifier|
      validate_item_identifier(item_identifier, collection.name)
    end
    unless item_json["documents"].nil?
      item_json["documents"].each do |document|
        validate_document(document, collection, corpus_dir)
      end
    end

    # If the item documents contain both a dc:source and dc:identifier, check that they are the same
    expanded_item = JSON::LD::API.expand(item_json['metadata']).first
    unless expanded_item[MetadataHelper::DOCUMENT.to_s].nil?
      expanded_item[MetadataHelper::DOCUMENT.to_s].each do |document|
        unless document[MetadataHelper::IDENTIFIER.to_s].blank?  || document[MetadataHelper::SOURCE.to_s].blank?
          dc_id = document[MetadataHelper::IDENTIFIER.to_s].last['@value']
          dc_source = File.basename(document[MetadataHelper::SOURCE.to_s].last['@id'])
          unless dc_id == dc_source
            raise ResponseError.new(400), "Document dc:identifier #{dc_id} doesn't match the document source file name #{dc_source}"
          end
        end
      end
    end
  end

  # Validates required document parameters present and document file isn't already in the collection directory
  def validate_document(document_metadata, collection, corpus_dir)
    if document_metadata["identifier"].nil? or document_metadata["content"].nil?
      err_message = "identifier missing from document" if document_metadata["identifier"].nil?
      err_message = "content missing from document #{document_metadata["identifier"]}" if document_metadata["content"].nil?
      raise ResponseError.new(400), "#{err_message}"
    end
    validate_new_document_file(corpus_dir, document_metadata["identifier"], collection)
  end

  # Validates that the document file to be created/uploaded doesn't already exist in the collection directory
  def validate_new_document_file(corpus_dir, file_basename, collection)
    absolute_filename = File.join(corpus_dir, file_basename)
    if File.exists? absolute_filename
      raise ResponseError.new(412), "The file #{file_basename} has already been uploaded to the collection #{collection.name}"
    end
  end

  # Validates each of the uploaded files
  def validate_files(uploaded_files, collection, corpus_dir)
    uploaded_files.each do |uploaded_file|
      validate_uploaded_file(uploaded_file, collection, corpus_dir)
    end
  end

  # Validates the uploaded file request parameter is of the expected format
  def validate_uploaded_file(uploaded_file, collection, corpus_dir)
    unless uploaded_file.is_a? ActionDispatch::Http::UploadedFile
      raise ResponseError.new(412), "Error in file parameter."
    end
    validate_new_document_file(corpus_dir, uploaded_file.original_filename, collection)
  end

  # Validates all the document filenames match (in the @id, dc:identifier, dc:source)
  def validate_document_source(document_json_ld)
    expanded_metadata = JSON::LD::API.expand(document_json_ld).first
    source_path = URI(expanded_metadata[MetadataHelper::SOURCE.to_s].first['@id']).path
    meta_source_basename = File.basename(source_path)
    rdf_subject_basename = File.basename(expanded_metadata['@id'])
    meta_id = expanded_metadata[MetadataHelper::IDENTIFIER.to_s].first['@value']
    raise ResponseError.new(400), "Document file name in @id doesn't match the document source file name" if meta_source_basename != rdf_subject_basename
    raise ResponseError.new(400), "Document dc:identifier doesn't match the document source file name" if meta_source_basename != meta_id
  end

end