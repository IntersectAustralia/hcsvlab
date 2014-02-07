require 'json/ld'
require 'net/http'
require 'uri'
require 'rdf/turtle'


class UserAnnotation < ActiveRecord::Base
  belongs_to :user
  attr_accessible :file_location, :file_type, :item_identifier, :original_filename, :shareable, :size_in_bytes, :annotationCollectionId

  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env]

  ANNOTATIONS_BASE_URI = "http://hcsvlab.org.au/corpora/"
  USER_BASE_URI = "http://hcsvlab.org.au/users/"

  RDF_TYPE = RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  DC_CREATOR = RDF::URI.new("http://purl.org/dc/terms/creator")

  #
  # Creates a new user annotations and relates it with the 'user'
  #
  # @param  [User] user
  # @param  [String] item_handle
  # @param  [ActionDispatch::Http::UploadedFile] uploaded_file
  #
  def self.create_new_user_annotation(user, item_handle, uploaded_file)
    new_annotation = nil
    begin
      collection_name = item_handle.split(":").first
      user_email = user.email.gsub("@", "_at_")

      # First will create the directory structure to store the uploaded file
      timeNow = Time.now
      base_path = Rails.application.config.user_annotations_location

      # File path will be BASE_PATH/COLLECTION_NAME/ITEM_HANDLE/USER_EMAIL/YEAR/MONTH/DAY
      absolute_file_path = File.join([base_path, collection_name, item_handle, user_email, timeNow.year.to_s, timeNow.month.to_s, timeNow.day.to_s])

      new_file_name = "#{item_handle.gsub(":", "_")}-#{user_email}-#{timeNow.to_i}#{File.extname(uploaded_file.original_filename)}"
      absolute_filename = File.join([absolute_file_path, new_file_name])

      unless File.directory?(absolute_file_path)
        FileUtils.mkdir_p(absolute_file_path)
      end

      # Now we copy the uploaded annotation file. The purpose of storing this file in the filesystem is backup.
      Rails.logger.debug("Copying annotations file from #{uploaded_file.tempfile} to #{absolute_filename}")
      FileUtils.cp uploaded_file.tempfile, absolute_filename

      # Read the JSON-LD content and create the RDF version
      file_content = IO.read(absolute_filename)
      uploadedFileJson = JSON.parse(file_content)
      uploadedFileRdf = JSON::LD::API.toRDF(uploadedFileJson)

      # Retrieve item identifier from Sesame
      dumpedGraph, annotationCollectionId = createRDFGraph(uploadedFileRdf, collection_name, item_handle, user)

      # Then we create a registry of the uploaded annotation
      new_annotation = register_uploaded_annotation(absolute_filename, item_handle, uploaded_file, user, annotationCollectionId)

      # Saves file in filesystem. The purpose of storing this file in the filesystem is backup.
      new_generated_rdf_file_name = "#{item_handle.gsub(":", "_")}-#{user_email}-#{timeNow.to_i}.rdf"
      absolute_rdf_filename = File.join([absolute_file_path, new_generated_rdf_file_name])

      File.open(absolute_rdf_filename, 'w') {|f| f.write(dumpedGraph) }

      # Now we have to send the generated RDF file to sesame. A context will be created for this annotation
      context = annotationCollectionId
      storeRdfInTriplestore(absolute_rdf_filename, collection_name, context)

    rescue => e
      # If something went wrong, we have to remove the copied file and created directories
      remove_created_files_and_directories(absolute_file_path, absolute_filename, absolute_rdf_filename, base_path)

      # Removes entry for the new annotations
      if !new_annotation.nil? and new_annotation.persisted?
        new_annotation.destroy
      end

      # Finally, remove added triples from the triple store
      removeTriplesFromContext(collection_name, context) if context.present?

      Rails.logger.error("Error Processing uploaded annotation - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    end

    return true
  end


  private

  #
  # Creates a new registry of the uploaded annotation
  #
  # @param [String] absolute_filename
  # @param [String] item_handle
  # @param [ActionDispatch::Http::UploadedFile]
  # @param [User] user
  #
  # @return [UserAnnotation]
  #
  def self.register_uploaded_annotation(absolute_filename, item_handle, uploaded_file, user, annotationCollectionId)
    new_annotation = self.new
    new_annotation.user = user
    new_annotation.original_filename = uploaded_file.original_filename
    new_annotation.file_type = uploaded_file.content_type
    new_annotation.size_in_bytes = uploaded_file.size
    new_annotation.item_identifier = item_handle
    new_annotation.shareable = true
    new_annotation.file_location = absolute_filename
    new_annotation.annotationCollectionId = annotationCollectionId.to_s
    new_annotation.save!
    new_annotation
  end

  #
  # Extracts the information in rdfStatements and creates a new RDF with custom information. The
  # returned RDF is in turtle format.
  #
  # @param [Array{RDF::Statement}] rdfStatements
  # @param [String] collection_name
  # @param [String] item_handle
  # @param [User] user
  #
  # @return [String, RDF::URI]
  #
  def self.createRDFGraph(rdfStatements, collection_name, item_handle, user)
    prefixes = {:rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                :dada => "http://purl.org/dada/schema/0.2#",
                :foaf => "http://xmlns.com/foaf/0.1/",
                :dc => "http://purl.org/dc/terms/"}

    item_identifier = retrieve_item_identifier(collection_name, item_handle)

    graph = RDF::Graph.new

    # Creates annotation collection
    annotationCollectionId = RDF::URI.new("#{ANNOTATIONS_BASE_URI}#{collection_name}/#{item_handle.gsub(":", "_")}/#{SecureRandom.uuid}")
    graph << RDF::Statement.new(annotationCollectionId, RDF_TYPE, RDF::URI.new("http://purl.org/dada/schema/0.2#AnnotationCollection"))
    graph << RDF::Statement.new(annotationCollectionId, RDF::URI.new("http://purl.org/dada/schema/0.2#annotates"), item_identifier)
    graph << RDF::Statement.new(annotationCollectionId, RDF::URI.new("http://purl.org/dc/terms/created"), Time.now.strftime("%d/%m/%Y %H:%M:%S"))

    userIdUri = RDF::URI.new("#{USER_BASE_URI}#{Digest::MD5.hexdigest(user.email)}")
    graph << RDF::Statement.new(annotationCollectionId, DC_CREATOR, userIdUri)
    graph << RDF::Statement.new(userIdUri, RDF_TYPE, RDF::URI.new("http://xmlns.com/foaf/0.1/Person"))
    graph << RDF::Statement.new(userIdUri, RDF::URI.new("http://xmlns.com/foaf/0.1/name"), "#{user.first_name} #{user.last_name}")

    annotationIdMap = {}
    rdfStatements.each do |aStatement|
      if (aStatement.valid?)

        if (!annotationIdMap.has_key?(aStatement.subject))
          annotationIdMap[aStatement.subject] = RDF::URI.new("#{annotationCollectionId.to_s}/#{SecureRandom.uuid}")
        end

        # Creates annotation
        annotationIdUri = annotationIdMap[aStatement.subject]
        locatorIdUri = RDF::URI.new("#{annotationIdUri.to_s}/Locator")

        graph << RDF::Statement.new(annotationIdUri, RDF_TYPE, RDF::URI.new("http://purl.org/dada/schema/0.2#Annotation"))
        graph << RDF::Statement.new(annotationIdUri, RDF::URI.new("http://purl.org/dada/schema/0.2#partof"), annotationCollectionId)
        graph << RDF::Statement.new(annotationIdUri, RDF::URI.new("http://purl.org/dada/schema/0.2#targets"), locatorIdUri)

        # Creates locator
        graph << RDF::Statement.new(locatorIdUri, aStatement.predicate, aStatement.object)
      else
        raise Exception.new("Error while parsing the annotations.")
      end
    end

    dumpedGraph = graph.dump(:ttl, :prefixes => prefixes)
    [dumpedGraph, annotationCollectionId]
  end

  #
  # Store tiples in the triple store.
  #
  # @param [String] absolute_filename
  # @param [String] collection_name
  # @param [RDF:URI] context
  #
  def self.storeRdfInTriplestore(absolute_filename, collection_name, context)
    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(collection_name)

    raise Exception.new("Repository #{collection_name} not found in sesame server") if (repository.nil?)

    repository.insert_from_rdf_files([absolute_filename], context)

  end

  #
  # Retrieves the full item identifier from Sesame server
  #
  # @param [String] collection_name
  # @param [String] item_handle
  #
  # @return [String]
  #
  def self.retrieve_item_identifier(collection_name, item_handle)
    item_short_identifier = item_handle.split(":").last

    server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(collection_name)

    raise Exception.new("Repository #{collection_name} not found in sesame server") if (repository.nil?)

    sparqlQuery ="""
        PREFIX dc: <http://purl.org/dc/terms/>

        SELECT ?identifier
        WHERE {
          ?identifier dc:identifier '#{item_short_identifier}'.
        }
    """

    result = repository.sparql_query(sparqlQuery)

    raise Exception.new("No item with identifier '#{item_short_identifier}' found in Repository '#{collection_name}' in sesame server") if (result.empty?)

    result.each.first['identifier']
  end

  #
  # Removes files and directories
  #
  # @param [String] absolute_file_path
  # @param [String] absolute_filename
  # @param [String] absolute_file_path
  # @param [String] base_path
  #
  def self.remove_created_files_and_directories(absolute_file_path, absolute_filename, absolute_rdf_filename, base_path)
    if (!absolute_filename.nil? and File.exists?(absolute_filename))
      FileUtils.rm(absolute_filename)
    end

    if (!absolute_rdf_filename.nil? and File.exists?(absolute_rdf_filename))
      FileUtils.rm(absolute_rdf_filename)
    end

    #Remove created directories
    directory = absolute_file_path
    while (!Pathname(base_path).realpath.eql?(Pathname(directory).realpath) and Dir["#{directory}/*"].empty?)
      FileUtils.rm_r(directory)
      directory = Pathname(directory).parent
    end
  end

  #
  # Removes triples from context
  #
  # @param [String] collection_name
  # @param [RDF::URI] context
  #
  def self.removeTriplesFromContext(collection_name, context)
    begin
      server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository(collection_name)

      repository.clear({context: context}) if !repository.nil?
    rescue => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end

end
