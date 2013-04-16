
namespace :fedora do
	
	task :ingest => :environment do

		corpus_dir  = ARGV[1] unless ARGV[1].nil?

		if (corpus_dir.nil?) || (! Dir.exists?(corpus_dir))
			puts "Usage: rake fedora:ingest <corpus folder>"
			exit 1
		end

		puts "Ingesting corpus from " + corpus_dir.to_s

		Dir.glob( corpus_dir + '/*-metadata.rdf') do |rdf_file|

			puts "Ingesting: " + rdf_file.to_s

			item = Item.new

			item.descMetadata.graph.load( rdf_file, :format => :ttl )

			item.label = item.descMetadata.graph.statements.first.subject

			item.save!

		end

	end

	task :clear => :environment do

		puts "Emptying Fedora"

		Item.find_each do | item |

			puts item.pid.to_s

			item.delete

		end
		
	end

end