


require 'find'

ENABLE_SOLR_UPDATES = false
ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']

namespace :fedora do
	
	task :ingest_one => :environment do

		corpus_rdf  = ARGV[1] unless ARGV[1].nil?

		if (corpus_rdf.nil?) || (! File.exists?(corpus_rdf))
			puts "Usage: rake fedora:ingest_one <corpus rdf file>"
			exit 1
		end

		ingest_rdf_file(File.dirname(corpus_rdf), corpus_rdf)

	end

	task :ingest => :environment do

		corpus_dir  = ARGV[1] unless ARGV[1].nil?

		if (corpus_dir.nil?) || (! Dir.exists?(corpus_dir))
			puts "Usage: rake fedora:ingest <corpus folder>"
			exit 1
		end

		puts "Ingesting corpus from " + corpus_dir.to_s
		errors = {}
		success_count = 0

		Dir.glob( corpus_dir + '/*-metadata.rdf') do |rdf_file|
			begin
				ingest_rdf_file(corpus_dir, rdf_file)
				success_count += 1
			rescue => e
				puts "Error! #{e.message}"
				errors[rdf_file] = e.message
			end
		end

		logfile   = "log/ingest_#{File.basename(corpus_dir)}.log"
		logstream = File.open(logfile, "w")

        message = "Successfully ingested #{success_count} Item#{success_count==1? '': 's'}"
		message += ", and rejected #{errors.size} Item#{errors.size==1? '': 's'}" unless errors.empty?
        puts message
		puts "Summary written to #{logfile}"

		if errors.empty?
        	logstream << message << "\n"
		else
        	logstream << "Ingest of #{corpus_dir}" << "\n\n"
        	logstream << message << "\n\n"
			logstream << "Error Summary" << "\n"
			logstream << "=============" << "\n"
        	errors.each { |item, message|
        		logstream << "\nItem #{item}:" << "\n\n"
        		logstream << "#{message}" << "\n"
        	}
    	end
		logstream.close
	end

	task :clear => :environment do

		puts "Emptying Fedora"

		Item.find_each do | item |
			puts item.pid.to_s
			item.delete
		end

		Document.find_each do | doc |
			puts doc.pid.to_s
			doc.delete
		end

	end

	task :clear_corpus do

        corpus = ENV['corpus']

		if (corpus.nil?)
			puts "Usage: rake fedora:clear_corpus corpus=<corpus name>"
			exit 1
		end

		objects = ActiveFedora::Base.find_with_conditions( {'DC_is_part_of' => corpus }, :rows => 1000000 )

		puts "Removing " + objects.count.to_s + " objects"

		objects.each do |obj|
  			id = obj["id"].to_s
  			puts "Removing: " + id.to_s
  			fobj=ActiveFedora::Base.find(id)
  			fobj.delete
		end

	end


	task :reindex_one => :environment do
		item_id  = ENV['item']

		if item_id.nil?
			puts "Usage: rake fedora:reindex_one item=<item id>"
			exit 1
		end

		unless item_id =~ /hcsvlab:[0-9]+/
			puts "Error: invalid item id, expecting 'hcsvlab:<digits>'"
			exit 1
		end

		stomp_client = Stomp::Client.open "stomp://localhost:61613"
		reindex_item(item_id, stomp_client)
	end


	task :reindex_corpus do

        corpus = ENV['corpus']

		if (corpus.nil?)
			puts "Usage: rake fedora:reindex_corpus corpus=<corpus name>"
			exit 1
		end

		objects = ActiveFedora::Base.find_with_conditions( {'DC_is_part_of' => corpus }, :rows => 1000000 )

		puts "Reindexing " + objects.count.to_s + " objects"

		stomp_client = Stomp::Client.open "stomp://localhost:61613"
		objects.each do |obj|
  			id = obj["id"].to_s
  			reindex_item(id, stomp_client)
		end

	end


	def ingest_rdf_file(corpus_dir, rdf_file)
		puts "Ingesting item: " + rdf_file.to_s

		item = create_item_from_file(rdf_file)
		look_for_annotations(item, rdf_file)
		look_for_documents(item, corpus_dir, rdf_file)

		item.save!

		# Msg to fedora.apim.update

		client = Stomp::Client.open "stomp://localhost:61613"
		client.publish('/queue/fedora.apim.update', "<xml><title type=\"text\">finishedWork</title><content type=\"text\">Fedora worker has finished with #{item.pid}</content><summary type=\"text\">#{item.pid}</summary> </xml>")
		client.close

	end

    def create_item_from_file(rdf_file)
		item = Item.new
		item.save!

		item.descMetadata.graph.load( rdf_file, :format => :ttl, :validate => true )
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
						doc.descMetadata.graph.load( rdf_file, :format => :ttl )
						doc.label = result.source
						doc.item = item
						# Only create a datastream for certain file types
						if STORE_DOCUMENT_TYPES.include? result.type.to_s
							case result.type.to_s
							when 'Text'
								item.add_file_datastream(File.open(path), {dsid: "primary_text", mimeType: "text/plain"})
							else
								puts "??? Creating a #{result.type.to_s} document for #{path} but not adding it to its Item"
							end
						end
						doc.save
						puts "#{result.type.to_s} Document = #{doc.pid.to_s}"
						break
					end
				end
			end
		end
	end

	def look_for_annotations(item, metadata_filename)
		annotation_filename = metadata_filename.sub("metadata", "ann")
		if File.exists?(annotation_filename)
			doc = Document.new
			doc.descMetadata.graph.load( annotation_filename, :format => :ttl )
			query = RDF::Query.new({
				:annotation => {
					RDF::URI("http://purl.org/dada/schema/0.2#partof") => :part_of
				}
			})
			results = query.execute(doc.descMetadata.graph)
			doc.label = results[0][:part_of] unless results.size == 0
			doc.item = item
			doc.save
			puts "Annotation Document = #{doc.pid.to_s}"
		end
	end

	def reindex_item(item_id, stomp_client)
		puts "Reindexing item: " + item_id
		stomp_client.publish('/queue/hcsvlab.solr.worker', "index #{item_id}")
	end


end
