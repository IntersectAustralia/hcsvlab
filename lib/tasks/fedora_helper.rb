require 'find'
ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']


def create_item_from_file(rdf_file)
  item = Item.new
  item.save!

  item.descMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.descMetadata.graph.statements.first.subject

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

  query.execute(item.descMetadata.graph).each do |result|
    filepath = corpus_dir + "/" + result.identifier.to_s
    # Only permit certain types (e.g. exlcude 'Raw' and 'Original')
    if ALLOWED_DOCUMENT_TYPES.include? result.type.to_s
      # Only create Documents if we have that file
      Find.find(corpus_dir) do |path|
        if File.basename(path).eql? result.identifier.to_s and File.file? path
          doc = Document.new
          doc.descMetadata.graph.load(rdf_file, :format => :ttl)
          doc.label = result.source
          doc.item = item
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
    end
  end
end

def look_for_annotations(item, metadata_filename)
  annotation_filename = metadata_filename.sub("metadata", "ann")
  return if annotation_filename == metadata_filename # HCSVLAB-441

  if File.exists?(annotation_filename)
    doc = Document.new
    doc.descMetadata.graph.load(annotation_filename, :format => :ttl)
    query = RDF::Query.new({
                               :annotation => {
                                   RDF::URI("http://purl.org/dada/schema/0.2#partof") => :part_of
                               }
                           })
    results = query.execute(doc.descMetadata.graph)
    doc.label = results[0][:part_of] unless results.size == 0
    doc.item = item
    doc.save
    item.add_named_datastream('annotation_set', :dsLocation => "file://" + annotation_filename, :mimeType => 'text/plain')
    puts "Annotation Document = #{doc.pid.to_s}" unless Rails.env.test?
  end
end

