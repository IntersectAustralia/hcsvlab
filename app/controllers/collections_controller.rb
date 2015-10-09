require Rails.root.join('lib/tasks/fedora_helper.rb')
require Rails.root.join('lib/api/response_error')
require Rails.root.join('lib/api/request_validator')
require 'fileutils'

class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource
  load_resource :only => [:create]
  skip_authorize_resource :only => [:create] # authorise create method with custom permission denied error

  set_tab :collection

  include RequestValidator

  PER_PAGE_RESULTS = 20
  #
  #
  #
  def index
    @collections = collections_by_name
    @collection_lists = lists_by_name
    respond_to do |format|
      format.html
      format.json
    end
  end

  #
  #
  #
  def show
    @collections = collections_by_name
    @collection_lists = lists_by_name

    @collection = Collection.find_by_name(params[:id])
    respond_to do |format|
      if @collection.nil? or @collection.name.nil?
        format.html { 
            flash[:error] = "Collection does not exist with the given id"
            redirect_to collections_path }
        format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
      else
        format.html { render :index }
        format.json {}
      end
    end
  end

  def create
    authorize! :create, @collection,
               :message => "Permission Denied: Your role within the system does not have sufficient privileges to be able to create a collection. Please contact an Alveo administrator."
    if request.format == 'json' and request.post?
      collection_name = params[:name]
      if !collection_name.nil? and !collection_name.blank? and !(collection_name.length > 255) and !(params[:collection_metadata].nil?)
        collection_uri = get_uri_from_metadata(params[:collection_metadata])
        if !Collection.find_by_uri(collection_uri).present?  # ingest skips collections with non-unique uri
          corpus_dir = create_metadata_and_manifest(collection_name, convert_json_metadata_to_rdf(params[:collection_metadata]))
          # Create the collection without doing a full ingest since it won't contain any item metadata
          collection = check_and_create_collection(collection_name, corpus_dir)
          collection.owner = User.find_by_authentication_token(params[:api_key])
          collection.save
          @success_message = "New collection '#{collection_name}' (#{collection_uri}) created"
        else
          respond_with_error("Collection '#{collection_name}' (#{collection_uri}) already exists in the system - skipping", 400)
        end
      else
        invalid_name = collection_name.nil? or collection_name.blank? or collection_name.length > 255
        invalid_metadata = params[:collection_metadata].nil?
        err_message = "name parameter" if invalid_name
        err_message = "metadata parameter" if invalid_metadata
        err_message = "name and metadata parameters" if invalid_name and invalid_metadata
        err_message << " not found" if !err_message.nil?
        respond_with_error(err_message, 400)
      end
    else
      respond_with_error("JSON-LD formatted metadata must be sent to the add collection api call as a POST request", 404)
    end
  end

  def collections_by_name
    Collection.not_in_list.order(:name)
  end

  def lists_by_name
    CollectionList.order(:name)
  end

  def new
  end

  #
  #
  #
  def add_licence_to_collection
    collection = Collection.find(params[:collection_id])
    licence = Licence.find(params[:licence_id])

    collection.set_licence(licence)

    flash[:notice] = "Successfully added licence to #{collection.name}"
    redirect_to licences_path(:hide=>(params[:hide] == true.to_s)?"t":"f")
  end

  #
  #
  #
  def change_collection_privacy
    collection = Collection.find(params[:id])
    private = params[:privacy]
    collection.set_privacy(private)
    if private=="false"
      UserLicenceRequest.where(:request_id => collection.id.to_s).destroy_all
    end
    private=="true" ? state="requiring approval" : state="not requiring approval"
    flash[:notice] = "#{collection.name} has been successfully marked as #{state}"
    redirect_to licences_path
  end

  #
  #
  #
  def revoke_access
    collection = Collection.find(params[:id])
    UserLicenceRequest.where(:request_id => collection.id.to_s).destroy_all if collection.private?
    UserLicenceAgreement.where(name: collection.name, collection_type: 'collection').destroy_all
    flash[:notice] = "All access to #{collection.name} has been successfully revoked"
    redirect_to licences_path
  end

  def add_items_to_collection
    # referenced documents (HCSVLAB-1019) are already handled by the look_for_documents part of the item ingest
    begin
      request_params = cleanse_params(params)
      corpus_dir = corpus_dir(request_params[:id])
      collection = validate_collection(request_params[:id], request_params[:api_key])
      validate_add_items_request(collection, corpus_dir, request_params[:items], request_params[:file])
      request_params[:items].each do |item_json|
        update_ids_in_jsonld(item_json["metadata"], collection)
      end
      uploaded_files = process_uploaded_files(corpus_dir, collection.name, request_params[:file])
      processed_items = process_items(collection.name, corpus_dir, request_params, uploaded_files)
      create_collection_manifest(corpus_dir)
      @success_message = ingest_items(corpus_dir, processed_items[:successes]) # Respond with a list of items added (via item ingest)
    rescue ResponseError => e
      respond_with_error(e.message, e.response_code)
      return # Only respond with one error at a time
    end
  end

  def add_document_to_item
    begin
      corpus_dir = corpus_dir(params[:collectionId])
      collection = validate_collection(params[:collectionId], params[:api_key])
      item = validate_item_exists(collection, params[:itemId])
      doc_metadata = params[:metadata]
      doc_content = params[:document_content]
      uploaded_file = params[:file]
      uploaded_file = uploaded_file.first if uploaded_file.is_a? Array
      doc_filename = get_dc_identifier(doc_metadata) # the document filename is the document id

      doc_metadata = format_and_validate_add_document_request(corpus_dir, collection, item, doc_metadata, doc_filename, doc_content, uploaded_file)
      create_document(item, doc_metadata)
      add_and_index_document(item, doc_metadata)
      @success_message = "Added the document #{doc_filename} to item #{params[:itemId]} in collection #{params[:collectionId]}"
    rescue ResponseError => e
      respond_with_error(e.message, e.response_code)
      return # Only respond with one error at a time
    end
  end

  def delete_item_from_collection
    begin
      corpus_dir = corpus_dir(params[:collectionId])
      collection = validate_collection(params[:collectionId], params[:api_key])
      item = validate_item_exists(collection, params[:itemId])
      remove_item(item, collection, corpus_dir)
      @success_message = "Deleted the item #{params[:itemId]} (and its documents) from collection #{params[:collectionId]}"
    rescue ResponseError => e
      respond_with_error(e.message, e.response_code)
      return # Only respond with one error at a time
    end
  end

  def edit_collection
    begin
      collection = validate_collection(params[:id], params[:api_key])
      validate_jsonld(params[:collection_metadata])
      new_metadata = format_update_collection_metadata(collection, params[:collection_metadata], params[:replace])
      write_metadata_graph_to_file(new_metadata, collection.rdf_file_path, format=:ttl)
      @success_message = "Updated collection #{collection.name}"
    rescue ResponseError => e
      respond_with_error(e.message, e.response_code)
      return # Only respond with one error at a time
    end
  end

  def update_item
    begin
      collection = validate_collection(params[:collectionId], params[:api_key])
      item = validate_item_exists(collection, params[:itemId])
      validate_jsonld(params[:metadata])
      new_metadata = format_update_item_metadata(item, params[:metadata])
      update_sesame_with_graph(new_metadata, collection)
      update_item_in_solr(item)
      @success_message = "Updated item #{item.get_name} in collection #{collection.name}"
    rescue ResponseError => e
      respond_with_error(e.message, e.response_code)
      return # Only respond with one error at a time
    end
  end

  private

  #
  # Creates the model for blacklight pagination.
  #
  #def create_pagination_structure(params)
  #  start = (params[:page].nil?)? 0 : params[:page].to_i-1
  #  total = @collections.length
  #
  #  per_page = (params[:per_page].nil?)? PER_PAGE_RESULTS : params[:per_page].to_i
  #  per_page = PER_PAGE_RESULTS if per_page < 1
  #
  #  current_page = (start / per_page).ceil + 1
  #  num_pages = (total / per_page.to_f).ceil
  #
  #  total_count = total
  #
  #  @collections = @collections[(current_page-1)*per_page..current_page*per_page-1]
  #
  #  start_num = start + 1
  #  end_num = start_num + @collections.length - 1
  #
  #  @paging = OpenStruct.new(:start => start_num,
  #                           :end => end_num,
  #                           :per_page => per_page,
  #                           :current_page => current_page,
  #                           :num_pages => num_pages,
  #                           :limit_value => per_page, # backwards compatibility
  #                           :total_count => total_count,
  #                           :first_page? => current_page > 1,
  #                           :last_page? => current_page < num_pages
  #  )
  #end

  # Returns directory path to the given corpus
  def corpus_dir(collection_name)
    File.join(Rails.application.config.api_collections_location, collection_name)
  end

  # Creates a file at the specified path with the given content
  def create_file(file_path, content)
    FileUtils.mkdir_p(File.dirname file_path)
    File.open(file_path, 'w') do |file|
      file.puts content
    end
  end

  # Coverts JSON-LD formatted collection metadata and converts it to RDF
  def convert_json_metadata_to_rdf(json_metadata)
    graph = RDF::Graph.new << JSON::LD::API.toRDF(json_metadata)
    # graph.dump(:ttl, prefixes: {foaf: "http://xmlns.com/foaf/0.1/"})
    graph.dump(:ttl)
  end

  # Gets the collection URI from JSON-LD formatted metadata
  def get_uri_from_metadata(json_metadata)
    graph = RDF::Graph.new << JSON::LD::API.toRDF(json_metadata)
    graph.statements.first.subject.to_s
  end

  # Writes the collection manifest as JSON and the metadata as .n3 RDF
  def create_metadata_and_manifest(collection_name, collection_rdf, collection_manifest={"collection_name" => collection_name, "files" => {}})
    corpus_dir = File.join(Rails.application.config.api_collections_location, collection_name)
    metadata_file_path = File.join(Rails.application.config.api_collections_location,  collection_name + '.n3')
    manifest_file_path = File.join(corpus_dir, MANIFEST_FILE_NAME)
    FileUtils.mkdir_p(corpus_dir)
    File.open(metadata_file_path, 'w') do |file|
      file.puts collection_rdf
    end
    File.open(manifest_file_path, 'w') do |file|
      file.puts(collection_manifest.to_json)
    end
    corpus_dir
  end

  # Creates a combined metadata.rdf file and returns the path of that file.
  # The file name takes the form of 'item1-item2-itemN-metadata.rdf'
  def create_combined_item_rdf(corpus_dir, item_names, item_rdf)
    create_item_rdf(corpus_dir, item_names.join("-"), item_rdf)
  end

  # creates an item-metadata.rdf file and returns the path of that file
  def create_item_rdf(corpus_dir, item_name, item_rdf)
    filename = File.join(corpus_dir, item_name + '-metadata.rdf')
    create_file(filename, item_rdf)
    filename
  end

  # Renders the given error message as JSON
  def respond_with_error(message, status_code)
    respond_to do |format|
      response = {:error => message}
      response[:failures] = params[:failures] unless params[:failures].blank?
      format.any { render :json => response.to_json, :status => status_code }
    end
  end

  # Adds the given message to the failures param
  def add_failure_response(message)
    params[:failures] = [] if params[:failures].nil?
    params[:failures].push(message)
  end

  # Uploads a document given as json content
  def upload_document_using_json(corpus_dir, file_basename, json_content)
    absolute_filename = File.join(corpus_dir, file_basename)
    Rails.logger.debug("Writing uploaded document contents to new file #{absolute_filename}")
    create_file(absolute_filename, json_content)
    absolute_filename
  end

  # Uploads a document given as a http multipart uploaded file or responds with an error if appropriate
  def upload_document_using_multipart(corpus_dir, file_basename, file, collection_name)
    absolute_filename = File.join(corpus_dir, file_basename)
    if !file.is_a? ActionDispatch::Http::UploadedFile
      raise ResponseError.new(412), "Error in file parameter."
    elsif file.blank? or file.size == 0
      raise ResponseError.new(412), "Uploaded file #{file_basename} is not present or empty."
    else
      Rails.logger.debug("Copying uploaded document file from #{file.tempfile} to #{absolute_filename}")
      FileUtils.cp file.tempfile, absolute_filename
      absolute_filename
    end
  end

  # Processes the metadata for each item in the supplied request parameters
  # Returns a hash containing :successes and :failures of processed items
  def process_items(collection_name, corpus_dir, request_params, uploaded_files)
    items = []
    failures = []
    request_params[:items].each do |item|
      item = process_item_documents_and_update_graph(corpus_dir, item)
      item = update_item_graph_with_uploaded_files(uploaded_files, item)
      begin
        validate_jsonld(item["metadata"])
        item["metadata"] = override_is_part_of_corpus(item["metadata"], collection_name)
        item_hash = write_item_metadata(corpus_dir, item) # Convert item metadata from JSON to RDF
        items.push(item_hash)
      rescue ResponseError
        failures.push('Unknown item contains invalid metadata')
      end
    end
    process_item_failures(failures) unless failures.empty?
    raise ResponseError.new(400), "No items were added" if items.blank?
    {:successes => items, :failures => failures}
  end

  # Adds failure message to response params
  def process_item_failures(failures)
    failures.each do |message|
      add_failure_response(message)
    end
  end

  # Uploads any documents in the item metadata and returns a copy of the item metadata with its metadata graph updated
  def process_item_documents_and_update_graph(corpus_dir, item_metadata)
    unless item_metadata["documents"].nil?
      item_metadata["documents"].each do |document|
        doc_abs_path = upload_document_using_json(corpus_dir, document["identifier"], document["content"])
        unless doc_abs_path.nil?
          item_metadata['metadata']['@graph'] = update_document_source_in_graph(item_metadata['metadata']['@graph'], document["identifier"], doc_abs_path)
        end
      end
    end
    item_metadata
  end

  # Updates the metadata graph for the given item
  # Returns a copy of the item with the document sourcs in the graph updates to the path of an uploaded file when appropriate
  def update_item_graph_with_uploaded_files(uploaded_files, item_metadata)
    uploaded_files.each do |file_path|
      item_metadata['metadata']['@graph'] = update_document_source_in_graph(item_metadata['metadata']['@graph'], File.basename(file_path), file_path)
    end
    item_metadata
  end

  # Updates the source of a specific document in the JSON formatted Item graph
  def update_document_source_in_graph(jsonld_graph, doc_identifier, doc_source)
    jsonld_graph.each do |graph_entry|
      # Handle documents nested within item metadata
      ["ausnc:document", MetadataHelper::DOCUMENT].each do |ausnc_doc|
        if graph_entry.has_key?(ausnc_doc)
          if graph_entry[ausnc_doc].is_a? Array
            graph_entry[ausnc_doc].each do |doc|
              update_doc_source(doc, doc_identifier, doc_source) # handle array of doc hashes
            end
          else
            update_doc_source(graph_entry[ausnc_doc], doc_identifier, doc_source) # handle single doc hash
          end
        end
      end

      # Handle documents contained in the same hash as item metadata
      update_doc_source(graph_entry, doc_identifier, doc_source)
    end
    jsonld_graph
  end

  # Updates the source of a specific document
  def update_doc_source(doc_metadata, doc_identifier, doc_source)
    if doc_metadata['dcterms:identifier'] == doc_identifier || doc_metadata[MetadataHelper::IDENTIFIER.to_s] == doc_identifier
      # Escape any filename spaces with '%20' as URIs with spaces are flagged as invalid when RDF loads
      formatted_source_path = {'@id' => "file://#{doc_source.sub(" ", "%20")}"}
      doc_has_source = false
      # Replace any existing document source with the formatted one or add one in if there aren't any existing
      ['dcterms:source', MetadataHelper::SOURCE.to_s].each do |source|
        if doc_metadata.has_key?(source)
          doc_metadata.update({source => formatted_source_path})
          doc_has_source = true
        end
      end
      doc_metadata.update({MetadataHelper::SOURCE.to_s => formatted_source_path}) unless doc_has_source
    end
  end

  # Returns a cleansed copy of params for the add item api
  def cleanse_params(request_params)
    if request_params[:items].is_a? String
      begin
        request_params[:items] = JSON.parse(request_params[:items])
      rescue JSON::ParserError
        raise ResponseError.new(400), "JSON item metadata is ill-formatted"
      end
    end
    request_params[:file] = [] if request_params[:file].nil?
    request_params[:file] = [request_params[:file]] unless request_params[:file].is_a? Array
    request_params
  end

  # Processes files uploaded as part of a multipart request
  def process_uploaded_files(corpus_dir, collection_name, files)
    uploaded_files = []
    files.each do |uploaded_file|
      uploaded_files.push(upload_document_using_multipart(corpus_dir, uploaded_file.original_filename, uploaded_file, collection_name))
    end
    uploaded_files
  end

  # Ingests a list of items
  def ingest_items(corpus_dir, items)
    items_ingested = []
    items.each do |item|
      ingest_one(corpus_dir, item[:rdf_file])
      item[:identifier].each {|id| items_ingested.push(id)}
    end
    items_ingested
  end

  # Write item JSON metadata to RDF file and returns a hash containing :identifier, :rdf_file
  def write_item_metadata(corpus_dir, item_json)
    rdf_metadata = convert_json_metadata_to_rdf(item_json["metadata"])
    item_identifiers = get_item_identifiers(item_json["metadata"])
    if item_identifiers.count == 1
      rdf_file = create_item_rdf(corpus_dir, item_identifiers.first, rdf_metadata)
    else
      rdf_file = create_combined_item_rdf(corpus_dir, item_identifiers, rdf_metadata)
    end
    {:identifier => item_identifiers, :rdf_file => rdf_file}
  end

  # Updates the item in Solr by re-indexing that item
  def update_item_in_solr(item)
    # ToDo: refactor this workaround into a proper test mock/stub
    if Rails.env.test?
      Solr_Worker.new.on_message("index #{item.id}")
    else
      stomp_client = Stomp::Client.open "stomp://localhost:61613"
      reindex_item_to_solr(item.id, stomp_client)
      stomp_client.close
    end
  end

  # Inserts the statements of the graph into the Sesame repository
  def insert_graph_into_repository(graph, repository)
    graph.each_statement { |statement| repository.insert(statement) }
  end

  # Inserts the metadata graph into the collection repository on the Sesame server
  def update_sesame_with_graph(graph, collection)
    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(collection.name)
    insert_graph_into_repository(graph, repository)
  end

  # Deletes statements with the item's URI from Sesame
  def delete_item_from_sesame(item, repository)
    item_subject = RDF::URI.new(item.uri)
    item_query = RDF::Query.new do
      pattern [item_subject, :predicate, :object]
    end
    item_statements = repository.query(item_query)
    item_statements.each do |item_statement|
      repository.delete(RDF::Statement(item_subject, item_statement[:predicate], item_statement[:object]))
    end
  end

  # Deletes statements with the document's derived URI from Sesame
  def delete_document_from_sesame(document, repository)
    document_query = RDF::Query.new do
      pattern [:subject, MetadataHelper::SOURCE, RDF::URI.new("file://#{document.file_path}")]
      pattern [:subject, MetadataHelper::IDENTIFIER, "#{document.file_name}"]
    end
    document_URIs = repository.query(document_query)
    if document_URIs.count == 1
      document_URI = document_URIs.first[:subject]
      document_statements_query = RDF::Query.new do
        pattern [document_URI, :predicate, :object]
      end
      document_statements = repository.query(document_statements_query)
      document_statements.each do |document_statement|
        repository.delete(RDF::Statement(document_URI, document_statement[:predicate], document_statement[:object]))
      end
    else
      Rails.logger.error "Cannot delete document RDF as multiple distinct document URIs match the document file name and path"
      document_URIs.each do |statement|
        Rails.logger.debug "#{RDF::Statement(statement[:subject], MetadataHelper::SOURCE, RDF::URI.new("file://#{document.file_path}"))}"
        Rails.logger.debug "#{RDF::Statement(statement[:subject], MetadataHelper::IDENTIFIER, "#{document.file_name}")}"
      end
    end
  end

  # Removes an item and its documents from the database, filesystem, Sesame and Solr
  def remove_item(item, collection, corpus_dir)
    delete_item_from_filesystem(item, corpus_dir)
    delete_from_sesame(item, collection)
    delete_item_from_solr(item.id)
    item.destroy # Remove from database (item, its documents and their document audits)
  end

  # Removes the metadata and document files for an item
  def delete_item_from_filesystem(item, corpus_dir)
    item_name = item.get_name
    delete_file(File.join(corpus_dir, "#{item_name}-metadata.rdf"))
    item.documents.each do |document|
      delete_file(document.file_path)
    end
  end

  # Deletes an item and its documents from Sesame
  def delete_from_sesame(item, collection)
    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(collection.name)
    delete_item_from_sesame(item, repository)
    item.documents.each do |document|
      delete_document_from_sesame(document, repository)
    end
  end

  # Attempts to delete a file or logs any exceptions raised
  def delete_file(file_path)
    begin
      File.delete(file_path)
    rescue => e
      Rails.logger.error e.inspect
      false
    end
  end

  # Writes a metadata RDF graph to a file in some optional format
  def write_metadata_graph_to_file(metadata_graph, file_path, format=:ttl)
    File.open(file_path, 'w') do |file|
      file.puts metadata_graph.dump(format)
    end
  end

  # Returns a copy of the combination of the given graphs
  def combine_graphs(graph1, graph2)
    temp_graph = RDF::Graph.new
    temp_graph << graph1
    temp_graph << graph2
    temp_graph
  end

  # Updates an old graph with the statements of a new graph
  #  Any statements in the old graph which have a matching subject and predicate as those in the new graph are deleted
  #  to ensure the graph is updated rather than appended to.
  def update_graph(old_graph, new_graph)
    temp_graph = combine_graphs(old_graph, new_graph)
    new_graph.each do |new_statement|
      matches = RDF::Query.execute(old_graph) {pattern [new_statement.subject, new_statement.predicate, :object]}
      matches.each do |match|
        # when combining graphs the resulting graph only contains distinct statements, so don't delete any fully matching statements
        unless match[:object] == new_statement.object
          temp_graph.delete([new_statement.subject, new_statement.predicate, match[:object]])
        end
      end
    end
    temp_graph
  end

  # Prints the statements of the graph to screen for easier inspection
  def inspect_graph_statements(graph)
    graph.each { |statement| puts statement.inspect }
  end

  # Prints the RDF statements in a collection repository for easier inspection
  def inspect_repository_statements(collection)
    repository = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s).repository(collection.name)
    inspect_graph_statements(repository)
  end

  # Formats the collection metadata given as part of the update collection API request
  # Returns an RDF graph of the updated/replaced collection metadata
  def format_update_collection_metadata(collection, new_jsonld_metadata, replace)
    new_jsonld_metadata["@id"] = collection.uri # Collection URI not allowed to change
    replacing_metadata = (replace == true) || (replace.is_a? String and replace.downcase == 'true')
    new_metadata = RDF::Graph.new << JSON::LD::API.toRDF(new_jsonld_metadata)
    if replacing_metadata
      return new_metadata
    else
      return update_graph(collection.rdf_graph, new_metadata)
    end
  end

  # Formats the item metadata given as part of the update item API request
  # Returns an RDF graph of the updated item metadata
  def format_update_item_metadata(item, metadata)
    metadata["@id"] = item.uri # Overwrite the item subject URI
    new_metadata = RDF::Graph.new << JSON::LD::API.toRDF(metadata)
    item_subject = RDF::URI.new(item.uri)
    # Remove any changes to un-editable metadata fields
    query = RDF::Query.new do
      pattern [item_subject, MetadataHelper::IDENTIFIER, :obj_identifier]
    end
    new_metadata.query(query).distinct.each do |solution|
      new_metadata.delete([item_subject, MetadataHelper::IDENTIFIER, solution[:obj_identifier]])
    end
    new_metadata
  end

  # Returns an Alveo formatted collection full URL
  def format_collection_url(collection_name)
    collection_url(collection_name)
  end

  # Returns an Alevo formatted item full URL
  def format_item_url(collection_name, item_name)
    catalog_url(collection_name, item_name)
  end

  # Retuns an Alveo formatted document full URL
  def format_document_url(collection_name, item_name, document_name)
    catalog_document_url(collection_name, item_name, document_name)
  end

  # Overrides the jsonld is_part_of_corpus with the collection's Alveo url
  def override_is_part_of_corpus(item_json_ld, collection_name)
    item_json_ld["@graph"].each do |node|
      is_doc = node["@type"] == MetadataHelper::DOCUMENT.to_s || node["@type"] == MetadataHelper::FOAF_DOCUMENT.to_s
      part_of_exists= false
      unless is_doc
        ["dcterms:isPartOf", MetadataHelper::IS_PART_OF.to_s].each do |is_part_of|
          if node.has_key?(is_part_of)
            node[is_part_of]["@id"] = format_collection_url(collection_name)
            part_of_exists = true
          end
        end
        unless part_of_exists
          node[MetadataHelper::IS_PART_OF.to_s] = {"@id" => format_collection_url(collection_name)}
        end
      end
    end
    item_json_ld
  end

  # Updates the @ids found in the JSON-LD to be the alveo catalog url
  def update_ids_in_jsonld(jsonld_metadata, collection)
    # NOTE: it is assumed that the metadata will contain only items at the outermost level and documents nested within them
    jsonld_metadata["@graph"].each do |item_metadata|
      item_id = get_dc_identifier(item_metadata)
      item_metadata = update_jsonld_item_id(item_metadata, collection.name) # Update item @ids
      item_metadata = update_document_ids_in_item(item_metadata, collection.name, item_id) # Update document @ids
      # Update display document and indexable document @ids
      doc_types = ["hcsvlab:display_document", MetadataHelper::DISPLAY_DOCUMENT.to_s, "hcsvlab:indexable_document", MetadataHelper::INDEXABLE_DOCUMENT]
      doc_types.each do |doc_type|
        if item_metadata.has_key?(doc_type)
          doc_short_id = item_metadata[doc_type]["@id"]
          item_metadata[doc_type]["@id"] = format_document_url(collection.name, item_id, doc_short_id)
        end
      end
    end
    jsonld_metadata
  end

  # Extracts the value of the dc:identifier from a metadata hash
  def get_dc_identifier(metadata)
    dc_id = nil
    ['dcterms:identifier', MetadataHelper::IDENTIFIER.to_s].each do |dc_id_predicate|
      dc_id = metadata[dc_id_predicate] if metadata.has_key?(dc_id_predicate)
    end
    dc_id
  end

  # Updates the @id of an item in JSON-LD to the Alveo catalog URL for that item
  def update_jsonld_item_id(item_metadata, collection_name)
    item_id = get_dc_identifier(item_metadata)
    item_metadata["@id"] = format_item_url(collection_name, item_id) unless item_id.nil?
    item_metadata
  end

  # Updates the @id of an document in JSON-LD to the Alveo catalog URL for that document
  def update_jsonld_document_id(document_metadata, collection_name, item_name)
    doc_id = get_dc_identifier(document_metadata)
    document_metadata["@id"] = format_document_url(collection_name, item_name, doc_id) unless doc_id.nil?
    document_metadata
  end

  # Updates the @id of documents within items in JSON-LD to the Alveo catalog URL for those documents
  def update_document_ids_in_item(item_metadata, collection_name, item_name)
    ['ausnc:document', MetadataHelper::DOCUMENT.to_s].each do |doc_predicate|
      if item_metadata.has_key?(doc_predicate)
        if item_metadata[doc_predicate].is_a? Array # When "ausnc:document" contains an array of document hashes
          item_metadata[doc_predicate].each do |document_metadata|
            document_metadata = update_jsonld_document_id(document_metadata, collection_name, item_name)
          end
        else # When "ausnc:document" contains a single document hash
          item_metadata[doc_predicate] = update_jsonld_document_id(item_metadata[doc_predicate], collection_name, item_name)
        end
      end
    end
    item_metadata
  end

  # Performs add document validations and returns the formatted metadata with the automatically generated metadata fields
  def format_and_validate_add_document_request(corpus_dir, collection, item, doc_metadata, doc_filename, doc_content, uploaded_file)
    validate_add_document_request(corpus_dir, collection, doc_metadata, doc_filename, doc_content, uploaded_file)
    doc_metadata = format_add_document_metadata(corpus_dir, collection, item, doc_metadata, doc_filename, doc_content, uploaded_file)
    validate_jsonld(doc_metadata)
    validate_document_source(doc_metadata)
    doc_metadata
  end

  # Format the add document metadata and add doc to file system
  def format_add_document_metadata(corpus_dir, collection, item, document_metadata, document_filename, document_content, uploaded_file)
    # Update the document @id to the Alveo catalog URI
    document_metadata = update_jsonld_document_id(document_metadata, collection.name, item.get_name)
    processed_file = nil
    unless uploaded_file.nil?
      processed_file = upload_document_using_multipart(corpus_dir, uploaded_file.original_filename, uploaded_file, collection.name)
    end
    unless document_content.blank?
      processed_file = upload_document_using_json(corpus_dir, document_filename, document_content)
    end
    update_doc_source(document_metadata, document_filename, processed_file) unless processed_file.nil?
    document_metadata
  end

  # Creates a document in the database from Json-ld document metadata
  def create_document(item, document_json_ld)
    expanded_metadata = JSON::LD::API.expand(document_json_ld).first
    file_path = URI(expanded_metadata[MetadataHelper::SOURCE.to_s].first['@id']).path
    file_name = File.basename(file_path)
    doc_type = expanded_metadata[MetadataHelper::TYPE.to_s]
    doc_type = doc_type.first['@value'] unless doc_type.nil?
    document = item.documents.find_or_initialize_by_file_name(file_name)
    if document.new_record?
      begin
        document.file_path = file_path
        document.doc_type = doc_type
        document.mime_type = mime_type_lookup(file_name)
        document.item = item
        document.item_id = item.id
        document.save
        logger.info "#{doc_type} Document = #{document.id.to_s}" unless Rails.env.test?
      rescue Exception => e
        logger.error("Error creating document: #{e.message}")
      end
    else
      raise ResponseError.new(412), "A file named #{file_name} is already in use by another document of item #{item.get_name}"
    end
  end

  # Adds a document to Sesame and updates the corresponding item in Solr
  def add_and_index_document(item, document_json_ld)
    # Upload doc rdf to seasame
    document_RDF = RDF::Graph.new << JSON::LD::API.toRDF(document_json_ld)
    update_sesame_with_graph(document_RDF, item.collection)
    #Add link in item rdf to doc rdf in sesame
    document_RDF_URI = RDF::URI.new(document_json_ld['@id'])
    item_document_link = {'@id' => item.uri, MetadataHelper::DOCUMENT.to_s => document_RDF_URI}
    append_item_graph = RDF::Graph.new << JSON::LD::API.toRDF(item_document_link)
    update_sesame_with_graph(append_item_graph, item.collection)
    #Reindex item in Solr
    delete_item_from_solr(item.id)
    update_item_in_solr(item)
  end

end