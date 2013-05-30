
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
				errors[rdf_file] = e.message
			end
		end

		logfile   = "ingest_#{File.basename(corpus_dir)}.log"
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

	def ingest_rdf_file(corpus_dir, rdf_file)

		puts "Ingesting item: " + rdf_file.to_s

		item = Item.new
		item.save!

		item.descMetadata.graph.load( rdf_file, :format => :ttl, :validate => true )
		item.label = item.descMetadata.graph.statements.first.subject

		puts "Item = " + item.pid.to_s
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
								item.primary_text.content = File.open(path)
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

		item.save!		

	end

end
