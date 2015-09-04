require "#{Rails.root}/lib/tasks/fedora_helper.rb"
require 'fileutils'

class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource
  load_resource :only => [:create]
  skip_authorize_resource :only => [:create] # authorise create method with custom permission denied error

  set_tab :collection

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
          ingest_corpus(corpus_dir)
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
      collection = Collection.find_by_name(params[:id])
      corpus_dir = corpus_dir(params[:id])
      cleanse_params
      validate_add_items_request(params)
      uploaded_files = process_uploaded_files(corpus_dir, collection.name)
      items = []
      params[:items].each do |item|
        # Upload the documents whose content was given as JSON for the current item
        if !item["documents"].nil?
          item["documents"].each do |document|
            doc_abs_path = upload_document_using_json(corpus_dir, document["identifier"], document["content"], collection.name)
            if !doc_abs_path.nil? # Update the document source in the item graph if upload is successful
              item['metadata']['@graph'] = update_document_source_in_graph(item['metadata']['@graph'], document["identifier"], doc_abs_path)
            end
          end
        end
        # Update the document source in the item graph if there were any files uploaded from a multipart HTTP request
        uploaded_files.each do |file_path|
          item['metadata']['@graph'] = update_document_source_in_graph(item['metadata']['@graph'], File.basename(file_path), file_path)
        end
        items.push(write_item_metadata(corpus_dir, item)) # Convert item metadata from JSON to RDF
      end
      create_collection_manifest(corpus_dir) # Re-create the collection manifest for item ingest
      raise ResponseError.new(400), "No items were added" if items.blank?
      @success_message = ingest_items(corpus_dir, items) # Respond with a list of items added (via item ingest)
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

  # Uploads a document given as json content or responds with an error if appropriate
  def upload_document_using_json(corpus_dir, file_basename, json_content, collection_name)
    absolute_filename = File.join(corpus_dir, file_basename)
    if File.exists? absolute_filename
      raise ResponseError.new(412), "The file \"#{file_basename}\" has already been uploaded to the collection #{collection_name}"
    else
      Rails.logger.debug("Writing uploaded document contents to new file #{absolute_filename}")
      create_file(absolute_filename, json_content)
      absolute_filename
    end
  end

  # Uploads a document given as a http multipart uploaded file or responds with an error if appropriate
  def upload_document_using_multipart(corpus_dir, file_basename, file, collection_name)
    absolute_filename = File.join(corpus_dir, file_basename)
    if !file.is_a? ActionDispatch::Http::UploadedFile
      raise ResponseError.new(412), "Error in file parameter."
    elsif file.blank? or file.size == 0
      raise ResponseError.new(412), "Uploaded file \"#{file_basename}\" is not present or empty."
    elsif File.exists? absolute_filename
      raise ResponseError.new(412), "The file \"#{file_basename}\" has already been uploaded to the collection #{collection_name}"
    else
      Rails.logger.debug("Copying uploaded document file from #{file.tempfile} to #{absolute_filename}")
      FileUtils.cp file.tempfile, absolute_filename
      absolute_filename
    end
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

  # Cleanses params for the add item api
  def cleanse_params
    params[:items] = JSON.parse(params[:items]) if params[:items].is_a? String
    params[:file] = [params[:file]] unless params[:file].nil? or params[:file].is_a? Array
  end

  # Processes files uploaded as part of a multipart request
  def process_uploaded_files(corpus_dir, collection_name)
    uploaded_files = []
    if !params[:file].nil?
      params[:file].each do |uploaded_file|
        uploaded_files.push(upload_document_using_multipart(corpus_dir, uploaded_file.original_filename, uploaded_file, collection_name))
      end
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

  # Validates the request on the add items api call
  def validate_add_items_request(params)
    collection = validate_collection(params)
    validate_items(params[:items], collection)
    validate_files(params[:file])
  end

  def validate_collection(params)
    collection = Collection.find_by_name(params[:id])
    if collection.nil?
      raise ResponseError.new(404), "Requested collection not found"
    elsif params[:api_key] != User.find(collection.owner_id).authentication_token
      raise ResponseError.new(403), "User is unauthorised" # Authorise by comparing api key sent with collection owner's api key
    end
    collection
  end

  def validate_items(items_metadata, collection)
    raise ResponseError.new(400), "JSON-LD formatted item metadata must be sent with the api request" if items_metadata.blank?
    items_metadata.each do |item|
      validate_item(item, collection)
    end
  end

  # Validates the item doesn't exist in the collection
  def validate_item(item_metadata, collection)
    existing_item = Item.find_by_handle("#{collection.name}:#{item_metadata["identifier"]}")
    if existing_item
      raise ResponseError.new(412), "The item #{item_metadata["identifier"]} already exists in the collection #{collection.name}"
    end
    if !item_metadata["documents"].nil?
      item_metadata["documents"].each do |document|
        validate_document(document, item_metadata)
      end
    end
  end

  # Validates required document parameters present
  def validate_document(document_metadata, item_metadata)
    if document_metadata["identifier"].nil? or document_metadata["content"].nil?
      err_message = "identifier missing from document" if document_metadata["identifier"].nil?
      err_message = "content missing from document #{document_metadata["identifier"]}" if document_metadata["content"].nil?
      err_message << " for item #{item_metadata["identifier"]}"
      raise ResponseError.new(400), "#{err_message}"
    end
  end

  def validate_files(uploaded_files)
    if !uploaded_files.nil?
      uploaded_files.each do |uploaded_file|
        validate_uploaded_file(uploaded_file)
      end
    end
  end

  # Validates the uploaded file request parameter is of the expected format
  def validate_uploaded_file(uploaded_file)
    if !uploaded_file.is_a? ActionDispatch::Http::UploadedFile
      raise ResponseError.new(412), "Error in file parameter."
    end
  end

end

class ResponseError < StandardError
  attr_reader :response_code
  def initialize(response_code=400)
    @response_code = response_code
  end
end