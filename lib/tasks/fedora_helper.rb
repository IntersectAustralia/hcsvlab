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
    raise ArgumentError, "#{rdf_file} does not appear to be a metadata file - at least, its name doesn't say 'metadata'"
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
  raise ArgumentError, "Error with file during manifest creation - #{rdf_file}" if !item_info["error"].nil?
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
    unless Rails.env.test?
      stomp_client = Stomp::Client.open "stomp://localhost:61613"
      reindex_item_to_solr(item.id, stomp_client)
      stomp_client.close
    end

    if existing_item
      logger.info "Item = #{existing_item.id} updated"
    else
      logger.info "Item = #{item.id} created"
    end
    return item, true
  end
end

def reindex_item_to_solr(item_id, stomp_client)
  logger.info "Reindexing item: #{item_id}"
  stomp_client.publish('/queue/alveo.solr.worker', "index #{item_id}")
end

def deindex_item_from_solr(item_id, stomp_client)
  logger.info "Deindexing item: #{item_id}"
  if Rails.env.test?
    Solr_Worker.new.on_message("delete #{item_id}")
  else
    stomp_client.publish('alveo.solr.worker.dlq', "delete #{item_id}")
  end
end

def check_and_create_collection(collection_name, corpus_dir)

  if collection_name == "ice" && File.basename(corpus_dir)!="ice" #ice has different directory structure
    dir = File.expand_path("../../..", corpus_dir)
  else
    dir = File.expand_path("..", corpus_dir)
  end

  if Dir.entries(dir).include?(collection_name + ".n3")
    coll_metadata = dir + "/" + collection_name + ".n3"
  else
    raise ArgumentError, "No collection metadata file found - #{dir}/#{collection_name}.n3. Stopping ingest."
  end

  collection = Collection.find_by_name(collection_name)

  is_new = false
  if collection.nil?
    is_new = true
    logger.info "Creating collection #{collection_name}"
    create_collection_from_file(coll_metadata, collection_name)
    collection = Collection.find_by_name(collection_name)
  else
    # Update RDF file path but don't save yet.
    collection.rdf_file_path = coll_metadata
  end

  paradisec_collection_setup(collection, is_new)

  populate_triple_store(corpus_dir, collection_name, "*-{metadata,ann}.rdf")

  collection.save
  collection
end

def paradisec_collection_setup(collection, is_new)
  collection_name = collection.name
  if collection_name[/^paradisec-/]
    if is_new
      # Default to Nick Thieberger
      data_owner = User.find_by_email('thien@unimelb.edu.au')
      data_owner = find_default_owner if data_owner.nil?

      # Create PARADISEC list automatically
      collection_list = CollectionList.find_or_initialize_by_name('PARADISEC')
      if collection_list.new_record?
        collection_list.owner = data_owner
        collection_list.private = true
        collection_list.licence = Licence.find_by_name('PARADISEC Conditions of Access')
        collection_list.save
      end

      collection.owner = data_owner
      collection.save
      collection_list.add_collections([collection.id])
    end

    graph = collection.rdf_graph
    query = RDF::Query.new({collection: {MetadataHelper::RIGHTS => :rights}})

    results = query.execute(graph)
    if results.present? and results[0][:rights].to_s[/Open/].blank?
      clear_collection_metadata(collection_name) # just in case
      raise ArgumentError, "Collection #{collection_name} (#{collection.uri}) is not an Open collection - skipping"
    end
  end

end

def create_collection_from_file(collection_file, collection_name)
  coll = Collection.new

  coll.rdf_file_path = collection_file
  graph = coll.rdf_graph
  coll.uri = graph.statements.first.subject.to_s
  coll.name = collection_name

  if Collection.find_by_uri(coll.uri).present?
    # There is already such a collection in the system
    logger.error "Collection #{collection_name} (#{coll.uri}) already exists in the system - skipping"
    return
  end
  set_data_owner(coll)

  coll.save!

  logger.info "Collection '#{coll.name}' Metadata = #{coll.id}" unless Rails.env.test?
end

def look_for_documents(item, corpus_dir, rdf_file, manifest)
  docs = manifest["files"][File.basename(rdf_file)]["docs"]

  # Create a primary text in the Item for primary text documents
  begin
    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(item.collection.name)

    query = RDF::Query.new do
      pattern [RDF::URI.new(item.uri), MetadataHelper::INDEXABLE_DOCUMENT, :indexable_doc]
      pattern [:indexable_doc, MetadataHelper::SOURCE, :source]
    end

    results = repository.query(query)

    results.each do |res|
      path = URI(res[:source]).path
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
    path = URI.decode(URI(source).path)
    type = result["type"]

    file_name = last_bit(source)
    doc = item.documents.find_or_initialize_by_file_name(file_name)
    if doc.new_record?
      begin
        doc.file_path = path
        doc.doc_type = type
        doc.mime_type = mime_type_lookup(file_name)
        doc.item = item
        doc.item_id = item.id

        doc.save

        logger.info "#{type} Document = #{doc.id.to_s}" unless Rails.env.test?
      rescue Exception => e
        logger.error("Error creating document: #{e.message}")
      end
    else
      update_document(doc, item, file_name, identifier, source, type, corpus_dir)
    end
  end

end

def update_document(document, item, file_name, identifier, source, type, corpus_dir)
  begin
    path = URI.decode(URI(source).path)

    document.file_name = file_name
    document.file_path = path
    document.doc_type = type
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
    logger.info "#{type} Document = #{document.id.to_s}" unless Rails.env.test?
  rescue Exception => e
    logger.error("Error creating document: #{e.message}")
  end
end

def look_for_annotations(item, metadata_filename)
  annotation_filename = metadata_filename.sub("metadata", "ann")
  return if annotation_filename == metadata_filename # HCSVLAB-441

  #TODO could be removed once we completely rely on the triple store?
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
  query = RDF::Query.new({collection: {MetadataHelper::LOC_RESPONSIBLE_PERSON => :person}})

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
                                 RDF::URI(MetadataHelper::IS_PART_OF) => :collection
                             }
                         })
  result = query.execute(graph)[0]
  collection_name = last_bit(result.collection.to_s)
  # small hack to handle austalk for the time being, can be fixed up
  # when we look at getting some form of data uniformity
  if query.execute(graph).any? { |r| r.collection == "http://ns.austalk.edu.au/corpus" }
    collection_name = "austalk"
  end

  collection_name
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

def ingest_corpus(corpus_dir, num_spec=:all, shuffle=false, annotations=true)

  label = "Ingesting...\n"
  label += "   corpus:      #{corpus_dir}\n"
  label += "   amount:      #{num_spec}\n"
  label += "   random:      #{shuffle}\n"
  label += "   annotations: #{annotations}"
  puts label unless Rails.env.test?

  check_and_create_manifest(corpus_dir)

  overall_start = Time.now

  manifest_file = File.open(File.join(corpus_dir, MANIFEST_FILE_NAME))
  manifest = JSON.parse(manifest_file.read)
  manifest_file.close

  collection_name = manifest["collection_name"]
  begin
    collection = check_and_create_collection(collection_name, corpus_dir)
  rescue ArgumentError => e
    logger.error(e.message)
    puts e.message
    return
  end

  rdf_files = Dir.glob(corpus_dir + '/*-metadata.rdf')

  if num_spec == :all
    num = rdf_files.size
  elsif num_spec.is_a? String
    if num_spec.end_with?('%')
      # The argument is a percentage
      num_spec = num_spec.slice(0, num_spec.size-1) # drop the % sign
      percentage = num_spec.to_f
      if percentage == 0 || percentage > 100
        puts "   Percentage should be a number between 0 and 100"
        exit 1
      end
      num = ((rdf_files.size * percentage)/100).to_i
      num = 1 if num < 1
    else
      # The argument is just a number. Well, it should be.
      num = num_spec.to_i
      if num == 0 || num > rdf_files.size
        puts "   Amount should be a number between 0 and the number of RDF files in the corpus (#{rdf_files.size})"
        exit 1
      end
    end
  end

  logger.info "Ingesting #{num} file#{(num==1) ? '' : 's'} of #{rdf_files.size}"
  errors = {}
  successes = {}

  rdf_files.shuffle! if shuffle
  rdf_files = rdf_files.slice(0, num)

  rdf_files.each do |rdf_file|
    begin
      pid = ingest_rdf_file(corpus_dir, rdf_file, annotations, manifest, collection)

      successes[rdf_file] = pid
    rescue => e
      logger.error "Error! #{e.message}\n#{e.backtrace}"
      errors[rdf_file] = e.message
    end
  end

  report_results(label, corpus_dir, successes, errors)
  end_time = Time.now
  logger.info("Time for ingesting #{corpus_dir}: (#{'%.1f' % ((end_time.to_f - overall_start.to_f)*1000)}ms)")

end


def check_corpus(corpus_dir)

  puts "Checking #{corpus_dir}..."

  rdf_files = Dir.glob(corpus_dir + '/*-metadata.rdf')

  errors = {}
  handles = {}

  index = 0

  rdf_files.each do |rdf_file|
    begin
      index = index + 1
      handle = check_rdf_file(rdf_file, index, rdf_files.size)
      handles[handle] = Set.new unless handles.has_key?(handle)
      handles[handle].add(rdf_file)
      if handles[handle].size > 1
        puts "Duplicate handle #{handle} found in:"
        handles[handle].each { |filename|
          puts "\t#{filename}"
        }
      end
    rescue => e
      logger.error "File: #{rdf_file}: #{e.message}"
      errors[rdf_file] = e.message
    end
  end

  handles.keep_if { |key, value| value.size > 1 }
  report_check_results(rdf_files.size, corpus_dir, errors, handles)
end


def check_rdf_file(rdf_file, index, limit)
  unless rdf_file.to_s =~ /metadata/ # HCSVLAB-441
    raise ArgumentError, "#{rdf_file} does not appear to be a metadata file - at least, it's name doesn't say 'metadata'"
  end
  logger.info "Checking file #{index} of #{limit}: #{rdf_file}"
  graph = RDF::Graph.load(rdf_file, :format => :ttl, :validate => true)
  query = RDF::Query.new({
                             :item => {
                                 RDF::URI(MetadataHelper::IS_PART_OF) => :collection,
                                 RDF::URI(MetadataHelper::IDENTIFIER) => :identifier
                             }
                         })
  result = query.execute(graph)[0]
  identifier = result.identifier.to_s
  collection_name = last_bit(result.collection.to_s)

  # small hack to handle austalk for the time being, can be fixed up
  # when we look at getting some form of data uniformity
  if query.execute(graph).any? { |r| r.collection == "http://ns.austalk.edu.au/corpus" }
    collection_name = "austalk"
  end

  handle = "#{collection_name}:#{identifier}"
  logger.info "Handle is #{handle}"
  return handle
end


def report_results(label, corpus_dir, successes, errors)
  begin
    logfile = "log/ingest_#{File.basename(corpus_dir)}.log"
    logstream = File.open(logfile, "w")

    message = "Successfully ingested #{successes.size} Item#{successes.size==1 ? '' : 's'}"
    message += ", and rejected #{errors.size} Item#{errors.size==1 ? '' : 's'}" unless errors.empty?
    logger.info message
    logger.info "Writing summary to #{logfile}"

    logstream << "#{label}" << "\n\n"
    logstream << message << "\n"

    unless successes.empty?
      logstream << "\n"
      logstream << "Successfully Ingested" << "\n"
      logstream << "=====================" << "\n"
      successes.each { |item, message|
        logstream << "Item #{item} as #{message}" << "\n"
      }
    end

    unless errors.empty?
      logstream << "\n"
      logstream << "Error Summary" << "\n"
      logstream << "=============" << "\n"
      errors.each { |item, message|
        logstream << "\nItem #{item}:" << "\n\n"
        logstream << "#{message}" << "\n"
      }

      puts "Error ingesting #{File.basename(corpus_dir)} collection. See #{logfile} for details."
    end
  ensure
    logstream.close if !logstream.nil?
  end
end

def report_check_results(size, corpus_dir, errors, handles)
  begin
    logfile = "log/check_#{File.basename(corpus_dir)}.log"
    logstream = File.open(logfile, "w")

    message = "Checked #{size} metadata file#{size==1 ? '' : 's'}"
    message += ", finding #{errors.size} syntax error#{errors.size==1 ? '' : 's'}"
    message += ", and #{handles.size} duplicate handle#{handles.size==1 ? '' : 's'}"
    logger.info message
    logger.info "Writing summary to #{logfile}"

    logstream << "Checking #{corpus_dir}" << "\n\n"
    logstream << message << "\n"

    unless errors.empty?
      logstream << "\n"
      logstream << "Error Summary" << "\n"
      logstream << "=============" << "\n"
      errors.each { |item, message|
        logstream << "\nItem #{item}:" << "\n\n"
        logstream << "#{message}" << "\n"
      }
    end

    unless handles.empty?
      logstream << "\n"
      logstream << "Duplicate Handles" << "\n"
      logstream << "=================" << "\n"
      handles.each { |handle, list|
        logstream << "\nHandle #{handle}:" << "\n"
        list.each { |filename|
          logstream << "\t#{filename}" << "\n"
        }
      }
    end
  ensure
    logstream.close
  end
end


def parse_boolean(string, default=false)
  return default if string.blank? # nil.blank? returns true, so this is also a nil guard.
  return false if string =~ (/(false|f|no|n|0)$/i)
  return true if string =~ (/(true|t|yes|y|1)$/i)
  raise ArgumentError.new("invalid value for Boolean: \"#{string}\", should be \"true\" or \"false\"")
end

def find_corpus_items(corpus)
  response = @solr.get 'select', :params => {:q => 'collection_name_facet:' + corpus,
                                             :rows => 2147483647}
  response['response']['docs']
end

def setup_collection_list(list_name, licence, *collection_names)
  list = CollectionList.create_public_list(list_name, licence, *collection_names)
  logger.warn("Didn't create CollectionList #{list_name}") if list.nil?
end

def send_solr_message(command, objectID)
  info("Fedora_Worker", "sending instruction to Solr_Worker: #{command} #{objectID}")
  publish :solr_worker, "#{command} #{objectID}"
  debug("Fedora_Worker", "Cache size: #{@@cache.size}")
  @@cache.each_pair { |key, value|
    debug("Fedora_Worker", "   @cache[#{key}] = #{value}")
  }
end

#
# Store all metadata and annotations from the given directory in the triplestore
#
def clear_collection_metadata(collection_name)
  logger.info "Start clearing #{collection_name}"

  # clear Solr
  uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

  req = Net::HTTP::Post.new(uri)
  req.body = "<delete><query>collection_name_facet:#{collection_name}</query></delete>"

  req.content_type = "text/xml; charset=utf-8"
  req.body.force_encoding("UTF-8")
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  # Clear all metadata and annotations from the triple store
  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
  repository = server.repository(collection_name)
  repository.clear if repository.present?

  # Now will store every RDF file
  logger.info "Finished clearing #{collection_name}"
end

#
# Store all metadata and annotations from the given directory in the triplestore
#
def populate_triple_store(corpus_dir, collection_name, glob)
  logger.info "Start ingesting files matching #{glob} in #{corpus_dir}"

  server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)

  # First we will create the repository for the collection, in case it does not exists
  server.create_repository(RDF::Sesame::HcsvlabServer::NATIVE_STORE_TYPE, collection_name, "Metadata and Annotations for #{collection_name} collection")

  # Create a instance of the repository where we are going to store the metadata
  repository = server.repository(collection_name)

  # Now will store every RDF file
  repository.insert_from_rdf_files("#{corpus_dir}/**/#{glob}")

  logger.info "Finished ingesting files matching #{glob} in #{corpus_dir}"
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
      logger.error "Licence Name: #{l.name} not ingested: #{l.errors.messages.inspect}"
      next
    else
      logger.info "Licence '#{l.name}' = #{l.id}" unless Rails.env.test?
    end

  end
end


#
# Extract the last part of a path/URI/slash-separated-list-of-things
#
def last_bit(uri)
  str = uri.to_s # just in case it is not a String object
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
