require 'find'
require "#{Rails.root}/lib/rdf-sesame/hcsvlab_server.rb"


ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']
MANIFEST_FILE_NAME = "manifest.json"

SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

#
# Ingests a single item, creating both a collection object and manifest if they don't
# already exist. NOTE: the id variable should only be passed in for use in automated tests!
#
def ingest_one(corpus_dir, rdf_file)
  check_and_create_manifest(corpus_dir)
  manifest = JSON.parse(IO.read(File.join(corpus_dir, MANIFEST_FILE_NAME)))

  collection_name = manifest["collection_name"]
  collection = check_and_create_collection(collection_name, corpus_dir)

  ingest_rdf_file(corpus_dir, rdf_file, true, manifest, collection)
end

def ingest_rdf_file(corpus_dir, rdf_file, annotations, manifest, collection)
  unless rdf_file.to_s =~ /metadata/ # HCSVLAB-441
    raise ArgumentError, "#{rdf_file} does not appear to be a metadata file - at least, it's name doesn't say 'metadata'"
  end
  logger.info "Ingesting item: #{rdf_file}"

  item, update = create_item_from_file(corpus_dir, rdf_file, manifest, collection)

  if update
    look_for_annotations(item, rdf_file) if annotations

    look_for_documents(item, corpus_dir, rdf_file, manifest)

    item.save!
  end

  item.id
end

def create_item_from_file(corpus_dir, rdf_file, manifest, collection)
  item_info = manifest["files"][File.basename(rdf_file)]
  raise StandardError, "Error with file during manifest creation - #{rdf_file}" if !item_info["error"].nil?
  identifier = item_info["id"]
  uri = item_info["uri"]
  collection_name = manifest["collection_name"]
  handle = "#{collection_name}:#{identifier}"

  existing_item = Item.find_by_handle(handle)

  if existing_item.present? && File.mtime(rdf_file).utc < existing_item.updated_at.utc
    logger.info "Item = #{existing_item.id} already up to date"
    return existing_item, false
  else
    if existing_item
      item = existing_item
    else
      item = Item.new
    end

    item.handle = handle
    item.uri = uri
    item.collection = collection
    item.save!

    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    reindex_item_to_solr(item.id, stomp_client)
    stomp_client.close

    if existing_item
      logger.info "Item = #{existing_item.id} updated"
    else
      logger.info "Item = #{item.id} created"
    end
    return item, true
  end
end

def check_and_create_collection(collection_name, corpus_dir)
  collection = Collection.find_by_name(collection_name)
  if collection.nil?
    create_collection(collection_name, corpus_dir)
    collection = Collection.find_by_name(collection_name)
    populate_triple_store(corpus_dir, collection_name)

  end
  collection
end

def create_collection(collection_name, corpus_dir)
  logger.info "Creating collection #{collection_name}"
  if collection_name == "ice" && File.basename(corpus_dir)!="ice" #ice has different directory structure
    dir = File.expand_path("../../..", corpus_dir)
  else
    dir = File.expand_path("..", corpus_dir)
  end

  if Dir.entries(dir).include?(collection_name + ".n3")
    coll_metadata = dir + "/" + collection_name + ".n3"
  else
    logger.warn "No collection metadata file found - #{dir}/#{collection_name}.n3"
    return
  end

  create_collection_from_file(coll_metadata, collection_name)
end

def create_collection_from_file(collection_file, collection_name)
  coll = Collection.new

  coll.rdf_file_path = collection_file

  coll.uri = coll.rdf_graph.statements.first.subject.to_s
  coll.name = collection_name

  coll.private = false

  if Collection.find_by_uri(coll.uri).present?
    # There is already such a collection in the system
    logger.error "Collection #{collection_name} (#{coll.uri}) already exists in the system - skipping"
    return
  end
  coll.save

  set_data_owner(coll)

  coll.save!

  logger.info "Collection '#{coll.name}' Metadata = #{coll.id}" unless Rails.env.test?
end

def look_for_documents(item, corpus_dir, rdf_file, manifest)
  docs = manifest["files"][File.basename(rdf_file)]["docs"]

  # Create a primary text datastream in the fedora Item for primary text documents
    begin
      server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository(item.collection.name)

      query = RDF::Query.new do
        pattern [RDF::URI.new(item.uri), MetadataHelper::INDEXABLE_DOCUMENT, :indexable_doc]
        pattern [:indexable_doc, MetadataHelper::SOURCE, :source]
      end

      results = repository.query(query)

      results.each do |res|
        path = res[:source].value.gsub("file://", "")
        if File.exists? path and File.file? path
          item.primary_text_path = path
          item.save
        end
      end
    rescue => e
      Rails.logger.error e.inspect
      Rails.logger.error "Could not connect to triplestore - #{SESAME_CONFIG["url"].to_s}"
    end

  docs.each do |result|
    identifier = result["identifier"]
    source = result["source"]
    path = source.gsub("file:", "")
    type = result["type"]

    file_name = last_bit(source)
    existing_doc = item.documents.find_by_file_name(file_name)
    if existing_doc.blank?
      # Create a document in fedora
      begin
        doc = Document.new
        doc.file_name = file_name
        doc.file_path = path
        doc.doc_type      = type
        doc.mime_type = mime_type_lookup(file_name)
        doc.item = item
        doc.item_id = item.id

        doc.save

        logger.info "#{type} Document = #{doc.id.to_s}" unless Rails.env.test?
      rescue Exception => e
        logger.error("Error creating document: #{e.message}")
      end
    else
      update_document(existing_doc.first, item, file_name, identifier, source, type, corpus_dir)
    end
  end

end

def update_document(document, item, file_name, identifier, source, type, corpus_dir)
  begin
    path = source.gsub("file:", "")

    document.file_name = file_name
    document.file_path = path
    document.doc_type      = type
    document.mime_type = mime_type_lookup(file_name)
    document.item = item
    document.save

    logger.info "Path:" + path
    if File.exists? path and File.file? path and STORE_DOCUMENT_TYPES.include? type
      case type
        when 'Text'
          item.primary_text_path = path
          item.save
        else
          logger.warn "??? Creating a #{type} document for #{path} but not adding it to its Item" unless Rails.env.test?
      end
    end
    logger.info "#{type} Document = #{doc.id.to_s}" unless Rails.env.test?
  rescue Exception => e
    logger.error("Error creating document: #{e.message}")
  end
end

def look_for_annotations(item, metadata_filename)
  annotation_filename = metadata_filename.sub("metadata", "ann")
  return if annotation_filename == metadata_filename # HCSVLAB-441

  if File.exists?(annotation_filename)
    if item.annotation_path.blank?
      item.annotation_path = annotation_filename
      logger.info "Annotation datastream added for #{File.basename(annotation_filename)}" unless Rails.env.test?
    else
      item.annotation_path = annotation_filename
      logger.info "Annotation datastream updated for #{File.basename(annotation_filename)}" unless Rails.env.test?
    end
  end
end

#
# Find and set the data owner for the given collection
#
def set_data_owner(collection)

  # See if there is a responsible person specified in the collection's metadata
  query = RDF::Query.new({
                             :collection => {
                                 MetadataHelper::LOC_RESPONSIBLE_PERSON => :person
                             }
                         })

  results = query.execute(collection.rdf_graph)
  data_owner = find_system_user(results)
  data_owner = find_default_owner if data_owner.nil?
  if data_owner.nil?
    logger.warn "Cannot determine data owner for collection #{collection.name}"
  elsif data_owner.cannot_own_data?
    logger.warn "Proposed data owner #{data_owner.email} does not have appropriate permission - ignoring"
  else
    logger.info "Setting data owner to #{data_owner.email}"
    collection.owner = data_owner
    collection.save
  end
end

#
# Create collection manifest if one doesn't already exist
#
def check_and_create_manifest(corpus_dir)
  if !File.exists? File.join(corpus_dir, MANIFEST_FILE_NAME)
    create_collection_manifest(corpus_dir)
  end
end

#
# Create the collection manifest file for a directory
#
def create_collection_manifest(corpus_dir)
  logger.info("Creating collection manifest for #{corpus_dir}")
  overall_start = Time.now

  failures = []
  rdf_files = Dir.glob(corpus_dir + '/*-metadata.rdf')

  manifest_hash = {"collection_name" => extract_manifest_collection(rdf_files.first), "files" => {}}

  rdf_files.each do |rdf_file|
    filename, manifest_entry = extract_manifest_info(rdf_file)
    manifest_hash["files"][filename] = manifest_entry
    if !manifest_entry["error"].nil?
      failures << filename
    end
  end

  begin
    file = File.open(File.join(corpus_dir, MANIFEST_FILE_NAME), "w")
    file.puts(manifest_hash.to_json)
  ensure
    file.close if !file.nil?
  end

  endTime = Time.now
  logger.debug("Time for creating manifest for #{corpus_dir}: (#{'%.1f' % ((endTime.to_f - overall_start.to_f)*1000)}ms)")
  logger.debug("Failures: #{failures.to_s}") if failures.size > 0
end

#
# query the given rdf file to find the collection name
#
def extract_manifest_collection(rdf_file)
  graph = RDF::Graph.load(rdf_file, :format => :ttl, :validate => true)
  query = RDF::Query.new({
                           :item => {
                               RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection
                           }
                         })
  result = query.execute(graph)[0]
  collection_name = last_bit(result.collection.to_s)

  # small hack to handle austalk for the time being, can be fixed up
  # when we look at getting some form of data uniformity
  if query.execute(graph).any? {|r| r.collection == "http://ns.austalk.edu.au/corpus"}
    collection_name = "austalk"
  end
  return collection_name
end

#
# query the given rdf file to produce a hash item to add to the manifest
#
def extract_manifest_info(rdf_file)
  filename = File.basename(rdf_file)
  begin
    graph = RDF::Graph.load(rdf_file, :format => :ttl, :validate => true)
    query = RDF::Query.new({
                             :item => {
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                             }
                           })
    result = query.execute(graph)[0]
    identifier = result.identifier.to_s
    uri = result[:item].to_s

    hash = {"id" => identifier, "uri" => uri, "docs" => []}

    query = RDF::Query.new({
                             :document => {
                                 RDF::URI("http://purl.org/dc/terms/type") => :type,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier,
                                 RDF::URI("http://purl.org/dc/terms/source") => :source
                             }
                           })
    query.execute(graph).each do |result|
      hash["docs"].append({"identifier" => result.identifier.to_s, "source" => result.source.to_s, "type" => result.type.to_s})
    end
  rescue => e
    logger.error "Error! #{e.message}"
    return filename, {"error" => "parse-error"}
  end

  return filename, hash
end


#
# Store all metadata and annotations from the given directory in the triplestore
#
def populate_triple_store(corpus_dir, collection_name)
  logger.debug "Start ingesting metadata and annotations in #{corpus_dir}"
  metadataFiles = Dir["#{corpus_dir}/**/*-metadata.rdf"]

  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)

  # First we will create the repository for the collection, in case it does not exists
  server.create_repository(RDF::Sesame::HcsvlabServer::NATIVE_STORE_TYPE, collection_name, "Metadata and Annotations for #{collection_name} collection")

  # Create a instance of the repository where we are going to store the metadata
  repository = server.repository(collection_name)

  # Now will store every RDF file
  repository.insert_from_rdf_files(metadataFiles)

  annotationsFiles = Dir["#{corpus_dir}/**/*-ann.rdf"]
  # Now will store every RDF file
  repository.insert_from_rdf_files(annotationsFiles)

  #insert_access_control_info(collection_name, repository)

  logger.debug "Finished ingesting metadata and annotations in #{corpus_dir}"
end

#
# Given an RDF query result set, find the first system user corresponding to a :person
# in that result set. Or nil, should there be no such user/an empty result set.
#
def find_system_user(results)
  results.each { |result|
    next unless result.has_variables?([:person])
    q = result[:person].to_s
    u = User.find_by_email(q)
    return u if u
  }
  nil
end


#
# Find the default data owner
#
def find_default_owner
  logger.debug "looking for default_data_owner in the APP_CONFIG, e-mail is #{APP_CONFIG['default_data_owner']}"
  email = APP_CONFIG["default_data_owner"]
  User.find_by_email(email)
end


#
# Ingest default set of licences
#
def create_default_licences(root_path = "config")
  Rails.root.join(root_path, "licences").children.each do |lic|
    lic_info = YAML.load_file(lic)

    begin
      l = Licence.new
      l.name = lic_info['name']
      l.text = lic_info['text']
      l.private = false

      l.save!

    rescue Exception => e
      logger.error "Licence Name: #{l.name[0]} not ingested: #{l.errors.messages.inspect}"
      next
    else
      logger.info "Licence '#{l.name[0]}' = #{l.id}" unless Rails.env.test?
    end

  end
end


#
# Extract the last part of a path/URI/slash-separated-list-of-things
#
def last_bit(uri)
  str = uri.to_s                # just in case it is not a String object
  return str if str.match(/\s/) # If there are spaces, then it's not a path(?)
  return str.split('/')[-1]
end

#
# Rough guess at mime_type from file extension
#
def mime_type_lookup(file_name)
    case File.extname(file_name.to_s)

      # Text things
      when '.txt'
          return 'text/plain'
      when '.xml'
          return 'text/xml'

      # Images
      when '.jpg'
          return 'image/jpeg'
      when '.tif'
          return 'image/tif'

      # Audio things
      when '.mp3'
          return 'audio/mpeg'
      when '.wav'
          return 'audio/wav'

      # Video things
      when '.avi'
          return 'video/x-msvideo'
      when '.mov'
          return 'video/quicktime'
      when '.mp4'
          return 'video/mp4'

      # Other stuff
      when '.doc'
          return 'application/msword'
      when '.pdf'
          return 'application/pdf'

      # Default
      else
          return 'application/octet-stream'
    end
  end
