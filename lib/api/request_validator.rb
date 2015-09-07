require Rails.root.join('lib/api/response_error')

module RequestValidator

  # Validates the collection exists and the user is authorised to modify it
  def validate_collection(request_params)
    collection = Collection.find_by_name(request_params[:id])
    if collection.nil?
      raise ResponseError.new(404), "Requested collection not found"
    elsif request_params[:api_key] != User.find(collection.owner_id).authentication_token
      raise ResponseError.new(403), "User is unauthorised" # Authorise by comparing api key sent with collection owner's api key
    end
    collection
  end

  # Validates the request on the add items api call
  def validate_add_items_request(collection, corpus_dir, request_params)
    validate_items(request_params[:items], collection, corpus_dir)
    validate_files(request_params[:file], collection, corpus_dir)
    validate_document_identifiers(get_document_identifiers(request_params[:file], request_params[:items]))
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
    raise ResponseError.new(412), "The identifier \"#{duplicate_id}\" is used for multiple documents" unless duplicate_id.nil?
  end

  # Validates the metadata for each of the items
  def validate_items(items_metadata, collection, corpus_dir)
    raise ResponseError.new(400), "JSON-LD formatted item metadata must be sent with the api request" if items_metadata.blank?
    items_metadata.each do |item|
      validate_item(item, collection, corpus_dir)
    end
  end

  # Validates the item doesn't exist in the collection and validates any document metadata with the item
  def validate_item(item_metadata, collection, corpus_dir)
    existing_item = Item.find_by_handle("#{collection.name}:#{item_metadata["identifier"]}")
    if existing_item
      raise ResponseError.new(412), "The item #{item_metadata["identifier"]} already exists in the collection #{collection.name}"
    end
    unless item_metadata["documents"].nil?
      item_metadata["documents"].each do |document|
        validate_document(document, item_metadata, collection, corpus_dir)
      end
    end
  end

  # Validates required document parameters present and document file isn't already in the collection directory
  def validate_document(document_metadata, item_metadata, collection, corpus_dir)
    if document_metadata["identifier"].nil? or document_metadata["content"].nil?
      err_message = "identifier missing from document" if document_metadata["identifier"].nil?
      err_message = "content missing from document #{document_metadata["identifier"]}" if document_metadata["content"].nil?
      err_message << " for item #{item_metadata["identifier"]}"
      raise ResponseError.new(400), "#{err_message}"
    end
    validate_new_document_file(corpus_dir, document_metadata["identifier"], collection)
  end

  # Validates that the document file to be created/uploaded doesn't already exist in the collection directory
  def validate_new_document_file(corpus_dir, file_basename, collection)
    absolute_filename = File.join(corpus_dir, file_basename)
    if File.exists? absolute_filename
      raise ResponseError.new(412), "The file \"#{file_basename}\" has already been uploaded to the collection #{collection.name}"
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

end