


require 'find'

ENABLE_SOLR_UPDATES = false
ALLOWED_DOCUMENT_TYPES = ['Text', 'Image', 'Audio', 'Video', 'Other']
STORE_DOCUMENT_TYPES = ['Text']

namespace :fedora do
	
	#
	# Ingest one metadata file, given as an argument
	#
	task :ingest_one => :environment do

		corpus_rdf  = ARGV[1] unless ARGV[1].nil?

		if (corpus_rdf.nil?) || (! File.exists?(corpus_rdf))
			puts "Usage: rake fedora:ingest_one <corpus rdf file>"
			exit 1
		end

		ingest_rdf_file(File.dirname(corpus_rdf), corpus_rdf, true)

	end

	
	#
	# Ingest one corpus directory, given as an argument
	#
	task :ingest => :environment do

		# defaults
		num_spec = :all

		corpus_dir  = ENV['corpus'] unless ENV['corpus'].nil?
		num_spec    = ENV['amount'] unless ENV['amount'].nil?
		random      = parse_boolean(ENV['random'], false)
		annotations = parse_boolean(ENV['annotations'], true)

		if (corpus_dir.nil?) || (! Dir.exists?(corpus_dir))
			puts "Usage: rake fedora:ingest corpus=<corpus folder> [amount=<amount>] [random=<boolean>] [annotations=<boolean>]"
			puts "       <amount> can be an absolute number or a percentage: eg. 10 or 10%"
			puts "       <random> defaults to false"
			puts "       <annotations> defaults to true"
			exit 1
		end

		ingest_corpus(corpus_dir, num_spec, random, annotations)
	end

	
	#
	# Clear everything out of the system
	#
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

	
	#
	# Clear one corpus (given as corpus=<corpus-name>) out of the system
	#
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

	
	#
	# Reindex one item (given as item=<item-id>)
	#
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
		stomp_client.close
	end

	
	#
	# Reindex one corpus (given as corpus=<corpus-name>)
	#
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
		stomp_client.close

	end


	def ingest_corpus(corpus_dir, num_spec=:all, shuffle=false, annotations=true)

		label = "Ingesting...\n"
		label += "   corpus:      #{corpus_dir}\n"
		label += "   amount:      #{num_spec}\n"
		label += "   random:      #{shuffle}\n"
		label += "   annotations: #{annotations}"
		puts label

		rdf_files = Dir.glob( corpus_dir + '/*-metadata.rdf')

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

		puts "Ingesting #{num} file#{(num==1)? '': 's'} of #{rdf_files.size}"
		errors    = {}
		successes = {}

		rdf_files.shuffle! if shuffle
		rdf_files = rdf_files.slice(0, num)

		rdf_files.each do |rdf_file|
			begin
				pid = ingest_rdf_file(corpus_dir, rdf_file, annotations)
				successes[rdf_file] = pid
			rescue => e
				puts "Error! #{e.message}"
				errors[rdf_file] = e.message
			end
		end

		report_results(label, corpus_dir, successes, errors)
	end


	def ingest_rdf_file(corpus_dir, rdf_file, annotations)
		puts "Ingesting item: " + rdf_file.to_s

		item = create_item_from_file(rdf_file)
		look_for_annotations(item, rdf_file) if annotations
		look_for_documents(item, corpus_dir, rdf_file)

		item.save!

		# Msg to fedora.apim.update

		client = Stomp::Client.open "stomp://localhost:61613"
		client.publish('/queue/fedora.apim.update', "<xml><title type=\"text\">finishedWork</title><content type=\"text\">Fedora worker has finished with #{item.pid}</content><summary type=\"text\">#{item.pid}</summary> </xml>")
		client.close

		return item.pid
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


	def report_results(label, corpus_dir, successes, errors)
		logfile   = "log/ingest_#{File.basename(corpus_dir)}.log"
		logstream = File.open(logfile, "w")

        message = "Successfully ingested #{successes.size} Item#{successes.size==1? '': 's'}"
		message += ", and rejected #{errors.size} Item#{errors.size==1? '': 's'}" unless errors.empty?
        puts message
		puts "Writing summary to #{logfile}"

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
    	end
		logstream.close
	end


	def parse_boolean(string, default=false)
		return default if string.blank? # nil.blank? returns true, so this is also a nil guard.
		return false if string =~ (/(false|f|no|n|0)$/i)
		return true  if string =~ (/(true|t|yes|y|1)$/i)
		raise ArgumentError.new("invalid value for Boolean: \"#{string}\", should be \"true\" or \"false\"")
	end

end
