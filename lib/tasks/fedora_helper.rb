require 'find'
ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']


def create_item_from_file(rdf_file)
  item = Item.new
  item.save!

  item.rdfMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.rdfMetadata.graph.statements.first.subject

  query = RDF::Query.new({
                             :item => {
                                 RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                             }
                         })

  result = query.execute(item.rdfMetadata.graph)[0]
  item.collection = last_bit(result.collection.to_s)
  item.collection_id = result.identifier.to_s
  
  puts "Item = " + item.pid.to_s
  return item
end

def look_for_documents(item, corpus_dir, rdf_file)
  #Text
  query = RDF::Query.new({
                             :document => {
                                 RDF::URI("http://purl.org/dc/terms/type") => :type,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier,
                                 RDF::URI("http://purl.org/dc/terms/source") => :source
                             }
                         })

  query.execute(item.rdfMetadata.graph).each do |result|

    # Create a document in fedora
    begin
      doc = Document.new
      doc.file_name = last_bit(result.source.to_s)
      doc.type      = result.type.to_s
      doc.mime_type = mime_type_lookup(doc.file_name[0])
      doc.label     = result.source.to_s
      doc.rdfMetadata.graph.load(rdf_file, :format => :ttl)
      doc.add_named_datastream('content', :mimeType => doc.mime_type[0], :dsLocation => result.source.to_s)
      doc.item = item
      doc.save

      # Create a primary text datastream in the fedora Item for primary text documents
      Find.find(corpus_dir) do |path|
        if File.basename(path).eql? result.identifier.to_s and File.file? path
          # Only create a datastream for certain file types
          if STORE_DOCUMENT_TYPES.include? result.type.to_s
            case result.type.to_s
              when 'Text'
                item.add_file_datastream(File.open(path), {dsid: "primary_text", mimeType: "text/plain"})
              else
                puts "??? Creating a #{result.type.to_s} document for #{path} but not adding it to its Item" unless Rails.env.test?
            end
          end
          doc.save
          puts "#{result.type.to_s} Document = #{doc.pid.to_s}" unless Rails.env.test?
          break
        end
      end
    rescue Exception => e
      Rails.logger.warn("Error creating document: #{e.message}")
    end
  end
end

def look_for_annotations(item, metadata_filename)
  annotation_filename = metadata_filename.sub("metadata", "ann")
  return if annotation_filename == metadata_filename # HCSVLAB-441

  if File.exists?(annotation_filename)
    doc = Document.new
    doc.rdfMetadata.graph.load(annotation_filename, :format => :ttl)
    query = RDF::Query.new({
                               :annotation => {
                                   RDF::URI("http://purl.org/dada/schema/0.2#partof") => :part_of
                               }
                           })
    results = query.execute(doc.rdfMetadata.graph)
    doc.file_name = annotation_filename
    doc.type = 'Annotation'
    doc.label = results[0][:part_of] unless results.size == 0
    doc.item = item
    doc.save
    item.add_named_datastream('annotation_set', :dsLocation => "file://" + annotation_filename, :mimeType => 'text/plain')
    puts "Annotation Document = #{doc.pid.to_s}" unless Rails.env.test?
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