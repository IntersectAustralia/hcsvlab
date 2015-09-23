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
      uploaded_files = process_uploaded_files(corpus_dir, collection.name, request_params[:file])
      items = process_items(corpus_dir, request_params, uploaded_files)
      @success_message = ingest_items(corpus_dir, items) # Respond with a list of items added (via item ingest)
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
      new_metadata = format_update_collection_metadata(collection, params[:collection_metadata], params[:overwrite])
      write_metadata_graph_to_file(new_metadata, collection.rdf_file_path, format=:ttl)
      @success_message = "Updated collection #{collection.name}"
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

  # creates an item-metadata.rdf file and returns the path of that file
  def create_item_rdf(corpus_dir, item_name, item_rdf)
    filename = File.join(corpus_dir, item_name + '-metadata.rdf')
    create_file(filename, item_rdf)
    filename
  end

  # Renders the given error message as JSON
  def respond_with_error(message, status_code)
    respond_to do |format|
      format.any { render :json => {:error => message}.to_json, :status => status_code }
    end
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
      raise ResponseError.new(412), "Uploaded file \"#{file_basename}\" is not present or empty."
    else
      Rails.logger.debug("Copying uploaded document file from #{file.tempfile} to #{absolute_filename}")
      FileUtils.cp file.tempfile, absolute_filename
      absolute_filename
    end
  end

  # Processes the metadata for each item in the supplied request parameters and recreates the corpus collection manifest
  def process_items(corpus_dir, request_params, uploaded_files)
    items = []
    request_params[:items].each do |item|
      item = process_item_documents_and_update_graph(corpus_dir, item)
      item = update_item_graph_with_uploaded_files(uploaded_files, item)
      items.push(write_item_metadata(corpus_dir, item)) # Convert item metadata from JSON to RDF
    end
    raise ResponseError.new(400), "No items were added" if items.blank?
    create_collection_manifest(corpus_dir) # Re-create the collection manifest for item ingest
    items
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

  # Updates the source of a document in the JSON formatted Item graph
  def update_document_source_in_graph(json_graph, document_identifier, document_source)
    json_graph.each do |graph_entry|
      if graph_entry['dcterms:identifier'] == document_identifier
        # Escape any filename spaces with '%20' as URIs with spaces are flagged as invalid when RDF loads
        graph_entry.update({'dcterms:source' => {'@id' => "file://#{document_source.sub(" ", "%20")}"}})
        json_graph
      end
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
      items_ingested.push(item[:identifier])
    end
    items_ingested
  end

  # Write item JSON metadata to RDF file
  def write_item_metadata(corpus_dir, item_json)
    rdf_metadata = convert_json_metadata_to_rdf(item_json["metadata"])
    rdf_file = create_item_rdf(corpus_dir, item_json["identifier"], rdf_metadata)
    {:identifier => item_json["identifier"], :rdf_file => rdf_file}
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
    delete_from_solr(item)
    item.destroy # Remove from database (item, its documents and their document audits)
  end

  # Removes the metadata and document files for an item
  def delete_item_from_filesystem(item, corpus_dir)
    item_name = item.handle.split(":")[1]
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

  # Deletes an items index from Solr
  def delete_from_solr(item)
    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    deindex_item_from_solr(item.id, stomp_client)
    stomp_client.close
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
  # If there are conflicting statements between the graphs then graph2 statements are given priority over graph1 statements
  def combine_graphs(graph1, graph2)
    temp_graph = RDF::Graph.new
    temp_graph << graph1
    temp_graph << graph2
    temp_graph
  end

  # Formats the collection metadata given as part of the update/edit collection API request
  # Returns an RDF graph of the updated/overwritten collection
  def format_update_collection_metadata(collection, edited_metadata, overwrite)
    edited_metadata["@id"] = collection.uri # Collection URI not allowed to change
    new_metadata = RDF::Graph.new << JSON::LD::API.toRDF(edited_metadata)
    unless overwrite.is_a? String and overwrite.downcase == 'true'
      new_metadata = combine_graphs(new_metadata, collection.rdf_graph)
    end
    new_metadata
  end

end