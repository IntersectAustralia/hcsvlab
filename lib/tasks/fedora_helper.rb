require 'find'
ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']


def create_item_from_file(corpus_dir, rdf_file)
  # Loading the graph in memory consume about 70% of the time needed to create an item.
  # We are loading the whole graph in order to recover the collection_name and the item identifier
  # TODO: We should try to find a faster way to retrieve collection_name and item identifier
  #
  graph = RDF::Graph.load(rdf_file, :format => :ttl, :validate => true)
  query = RDF::Query.new({
                             :item => {
                                 RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                             }
                         })
  result = query.execute(graph)[0]
  identifier = result.identifier.to_s
  collection_name = last_bit(result.collection.to_s)

  # small hack to handle austalk for the time being, can be fixed up 
  # when we look at getting some form of data uniformity
  if query.execute(graph).any? {|r| r.collection == "http://ns.austalk.edu.au/corpus"}
    collection_name = "austalk"
  end

  handle = "#{collection_name}:#{identifier}"

  collection = Collection.find_and_load_from_solr({short_name: collection_name}).first
  if collection.nil?
    create_collection(collection_name, corpus_dir)
    collection = Collection.find_and_load_from_solr({short_name: collection_name}).first
  end

  # We can't use find_and_load_from_solr method here since the result is not a full DigitalObject
  # and thus we can't call methods like modified_date
  existingItem = Array(Item.where(:handle => handle)).first

  if !existingItem.nil? && File.mtime(rdf_file).utc < Time.parse(existingItem.modified_date)
    logger.info "Item = #{existingItem.id} already up to date"
    return existingItem, false
  elsif !existingItem.nil?
    logger.info "Item = #{existingItem.id} updated"
    return update_item_from_file(existingItem, graph, result), true
  else
    item = Item.new
    item.save!

    item.rdfMetadata.graph.insert(graph)
    item.label = item.rdfMetadata.graph.statements.first.subject

    item.handle = handle
    item.collection = collection

    # Add Groups to the created item
    item.set_discover_groups(["#{collection_name}-discover"], [])
    item.set_read_groups(["#{collection_name}-read"], [])
    item.set_edit_groups(["#{collection_name}-edit"], [])
    # Add complete permission for data_owner
    data_owner = item.collection.flat_private_data_owner
    if (!data_owner.nil?)
      item.set_discover_users([data_owner], [])
      item.set_read_users([data_owner], [])
      item.set_edit_users([data_owner], [])
    end

    logger.info "Item = #{item.pid} created"

    return item, true
  end
end

def update_item_from_file(item, graph, result)
  item.rdfMetadata.graph.clear
  item.rdfMetadata.graph.insert(graph)
  item.label = item.rdfMetadata.graph.statements.first.subject

  collection_name = last_bit(result.collection.to_s)
  item.collection = Collection.find_by_short_name(collection_name).first

  item.save!
  logger.info "Updated item = " + item.pid.to_s
  stomp_client = Stomp::Client.open "stomp://localhost:61613"
  reindex_item(item, stomp_client)
  item
end

def create_collection(collection_name, corpus_dir)
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

  coll.rdfMetadata.graph.load(collection_file, :format => :ttl, :validate => true)
  coll.label = coll.rdfMetadata.graph.statements.first.subject.to_s
  coll.uri = coll.label
  coll.short_name = collection_name
  coll.privacy_status = "false"

  if Collection.find_by_uri(coll.uri).size != 0
    # There is already such a collection in the system
    logger.error "Collection #{collection_name} (#{coll.uri}) already exists in the system - skipping"
    return
  end
  coll.save

  set_data_owner(coll)

  # Add Groups to the created collection
  coll.set_discover_groups(["#{collection_name}-discover"], [])
  coll.set_read_groups(["#{collection_name}-read"], [])
  coll.set_edit_groups(["#{collection_name}-edit"], [])
  # Add complete permission for data_owner
  data_owner = coll.flat_private_data_owner
  if (!data_owner.nil?)
    coll.set_discover_users([data_owner], [])
    coll.set_read_users([data_owner], [])
    coll.set_edit_users([data_owner], [])
  end

  coll.save!

  logger.info "Collection '#{coll.flat_short_name}' Metadata = #{coll.pid}" unless Rails.env.test?
end

def look_for_documents(item, corpus_dir)

  doc_ids = []

  query = RDF::Query.new({
                             :document => {
                                 RDF::URI("http://purl.org/dc/terms/type") => :type,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier,
                                 RDF::URI("http://purl.org/dc/terms/source") => :source
                             }
                         })
  query.execute(item.rdfMetadata.graph).each do |result|
    file_name = last_bit(result.source.to_s)
    existing_doc = Document.find_and_load_from_solr({:file_name => file_name, :item_id => item.id})
    if existing_doc.empty?
      # Create a document in fedora
      begin
        doc = Document.new
        doc.file_name = file_name
        doc.type      = result.type.to_s
        doc.mime_type = mime_type_lookup(doc.file_name[0])
        doc.label     = result.source.to_s
        doc.add_named_datastream('content', :mimeType => doc.mime_type[0], :dsLocation => result.source.to_s)
        doc.item = item
        doc.item_id = item.id

        # Add Groups to the created document
        logger.debug "Creating document groups (discover, read, edit)"
        doc.set_discover_groups(["#{item.collection.flat_short_name}-discover"], [])
        doc.set_read_groups(["#{item.collection.flat_short_name}-read"], [])
        doc.set_edit_groups(["#{item.collection.flat_short_name}-edit"], [])
        # Add complete permission for data_owner
        data_owner = item.collection.flat_private_data_owner
        if (!data_owner.nil?)
          logger.debug "Creating document users (discover, read, edit) with #{data_owner}"
          doc.set_discover_users([data_owner], [])
          doc.set_read_users([data_owner], [])
          doc.set_edit_users([data_owner], [])
        end

        doc.save
        doc_ids << doc.id

        # Create a primary text datastream in the fedora Item for primary text documents
        Find.find(corpus_dir) do |path|
          if File.basename(path).eql? result.identifier.to_s and File.file? path
            # Only create a datastream for certain file types
            if STORE_DOCUMENT_TYPES.include? result.type.to_s
              case result.type.to_s
                when 'Text'
                  item.add_file_datastream(File.open(path), {dsid: "primary_text", mimeType: "text/plain"})
                else
                  logger.warn "??? Creating a #{result.type.to_s} document for #{path} but not adding it to its Item" unless Rails.env.test?
              end
            end
            #doc.save
            logger.info "#{result.type.to_s} Document = #{doc.pid.to_s}" unless Rails.env.test?
            break
          end
        end
      rescue Exception => e
        logger.error("Error creating document: #{e.message}")
      end
    else
      update_document(existing_doc.first, item, file_name, result, corpus_dir)
      doc_ids << existing_doc.first.id
    end
  end
  return doc_ids
end

def update_document(document, item, file_name, result, corpus_dir)
  begin
    document.file_name = file_name
    document.type      = result.type.to_s
    document.mime_type = mime_type_lookup(document.file_name[0])
    document.label     = result.source.to_s
    document.update_named_datastream('content', :mimeType => document.mime_type[0], :dsid => "CONTENT1", :dsLocation => result.source.to_s)
    document.item = item
    document.item_id = item.id
    document.save

    # Update primary text datastream in the fedora Item for primary text documents
    Find.find(corpus_dir) do |path|
      if File.basename(path).eql? result.identifier.to_s and File.file? path
        # Only create a datastream for certain file types
        if STORE_DOCUMENT_TYPES.include? result.type.to_s
          case result.type.to_s
            when 'Text'
              item.add_file_datastream(File.open(path), {dsid: "primary_text", mimeType: "text/plain"})
              item.primary_text.save
            else
              logger.warn "??? Creating a #{result.type.to_s} document for #{path} but not adding it to its Item" unless Rails.env.test?
          end
        end
        logger.info "Updated #{result.type.to_s} Document = #{document.pid.to_s}" unless Rails.env.test?
        break
      end
    end
  rescue Exception => e
    logger.error("Error creating document: #{e.message}")
  end
end

def look_for_annotations(item, metadata_filename)
  annotation_filename = metadata_filename.sub("metadata", "ann")
  return if annotation_filename == metadata_filename # HCSVLAB-441

  if File.exists?(annotation_filename)
    if(item.named_datastreams["annotation_set"].empty?)
      item.add_named_datastream('annotation_set', :dsLocation => "file://" + annotation_filename, :mimeType => 'text/plain')
      logger.info "Annotation datastream added for #{File.basename(annotation_filename)}" unless Rails.env.test?
    else
      item.update_named_datastream('annotation_set', :dsid => "annotationSet1", :dsLocation => "file://" + annotation_filename,
       :mimeType => 'text/plain')
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

  results = query.execute(collection.rdfMetadata.graph)
  data_owner = find_system_user(results)
  data_owner = find_default_owner() if data_owner.nil?
  if data_owner.nil?
    logger.warn "Cannot determine data owner for collection #{collection.short_name}"
  elsif data_owner.cannot_own_data?
    logger.warn "Proposed data owner #{data_owner.email} does not have appropriate permission - ignoring"
  else
    logger.info "Setting data owner to #{data_owner.email}"
    collection.set_data_owner_and_save(data_owner)
  end
end


#
# Given an RDF query result set, find the first system user corresponding to a :person
# in that result set. Or nil, should there be no such user/an empty result set.
#
def find_system_user(results)
  results.each { |result|
    next unless result.has_variables?([:person])
    q = result[:person].to_s
    u = User.find_all_by_email(q)
    return u[0] if u.size > 0
  }
  return nil
end


#
# Find the default data owner
#
def find_default_owner()
  logger.debug "looking for default_data_owner in the APP_CONFIG, e-mail is #{APP_CONFIG['default_data_owner']}"
  email = APP_CONFIG["default_data_owner"]
  u = User.find_all_by_email(email)
  return u[0] if u.size > 0
  return nil
end


#
# Ingest default set of licences
#
def create_default_licences(rootPath = "config")
  Rails.root.join(rootPath, "licences").children.each do |lic|
    lic_info = YAML.load_file(lic)

    begin
      l = Licence.new
      l.name = lic_info['name']
      l.text = lic_info['text']
      l.type = Licence::LICENCE_TYPE_PUBLIC
      l.label = l.name

      l.save!
    rescue Exception => e
      logger.error "Licence Name: #{l.name[0]} not ingested: #{l.errors.messages.inspect}"
      next
    else
      logger.info "Licence '#{l.name[0]}' = #{l.pid}" unless Rails.env.test?
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