require File.dirname(__FILE__) + '/fedora_helper.rb'

namespace :fedora do

  @solr = RSolr.connect(Blacklight.solr_config)

  #
  # Ingest one metadata file, given as an argument
  #
  task :ingest_one => :environment do

    corpus_rdf = ARGV[1] unless ARGV[1].nil?

    if (corpus_rdf.nil?) || (!File.exists?(corpus_rdf))
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

    corpus_dir = ENV['corpus'] unless ENV['corpus'].nil?
    num_spec = ENV['amount'] unless ENV['amount'].nil?
    random = parse_boolean(ENV['random'], false)
    annotations = parse_boolean(ENV['annotations'], true)

    if (corpus_dir.nil?) || (!Dir.exists?(corpus_dir))
      if corpus_dir.nil?
        puts "No corpus directory specified."
      else
        puts "Corpus directory #{corpus_dir} does not exist."
      end
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

    puts "Items..."
    Item.find_each do |item|
      puts item.pid.to_s
      item.delete
    end

    puts "Documents..."
    Document.find_each do |doc|
      puts doc.pid.to_s
      doc.delete
    end

    puts "Collections..."
    Collection.find_each do |coll|
      puts coll.pid.to_s
      coll.delete
    end

    puts "Collection Lists"
    CollectionList.find_each do |aCollectionList|
      puts aCollectionList.pid.to_s
      aCollectionList.delete
    end

    puts "Licences"
    Licence.find_each do |aLicence|
      puts aLicence.pid.to_s
      aLicence.delete
    end

  end


  #
  # Clear one corpus (given as corpus=<corpus-name>) out of the system
  #
  task :clear_corpus => :environment do

    corpus = ENV['corpus']

    if (corpus.nil?)
      puts "Usage: rake fedora:clear_corpus corpus=<corpus name>"
      exit 1
    end

    #objects = ActiveFedora::Base.find_with_conditions( {'DC_is_part_of' => corpus }, :rows => 1000000 )
    objects = find_corpus_items corpus

    puts "Removing " + objects.count.to_s + " Items"

    documents = []

    objects.each do |obj|
      id = obj["id"].to_s
      puts "Removing Item: " + id.to_s
      fobj=Item.find(id)
      fobj.documents.each { |doc|
        documents << doc
      }
      fobj.delete
    end

    puts "Removing " + documents.size.to_s + " Documents"
    documents.each { |doc|
      puts "Removing Document: " + doc.pid
      doc.delete
    }

    Collection.find_by_short_name(corpus).each { |collection|
      puts "Removing collection object #{collection.pid}"
      collection.delete
    }
  end


  #
  # Reindex one item (given as item=<item-id>)
  #
  task :reindex_one => :environment do
    item_id = ENV['item']

    if item_id.nil?
      puts "Usage: rake fedora:reindex_one item=<item id>"
      exit 1
    end

    unless item_id =~ /hcsvlab:[0-9]+/
      puts "Error: invalid item id, expecting 'hcsvlab:<digits>'"
      exit 1
    end

    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    reindex_item_by_id(item_id, stomp_client)
    stomp_client.close
  end


  #
  # Reindex one corpus (given as corpus=<corpus-name>)
  #
  task :reindex_corpus => :environment do

    corpus = ENV['corpus']

    if (corpus.nil?)
      puts "Usage: rake fedora:reindex_corpus corpus=<corpus name>"
      exit 1
    end

    #objects = ActiveFedora::Base.find_with_conditions( {'DC_is_part_of' => corpus }, :rows => 1000000 )
    objects = find_corpus_items corpus

    puts "Reindexing " + objects.count.to_s + " objects"

    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    objects.each do |obj|
      reindex_item_by_id(obj["id"], stomp_client)
    end
    stomp_client.close

  end


  #
  # Reindex the whole blinkin' lot
  #
  task :reindex_all => :environment do

    items = Item.all

    puts "Reindexing everything - " + items.size.to_s + " objects"

    stomp_client = Stomp::Client.open "stomp://localhost:61613"

    items.each { |item|
      reindex_item(item, stomp_client)
    }

    stomp_client.close

  end

  #
  # Ingest and create default set of licenses
  #
  task :ingest_licences => :environment do
    create_default_licences
  end

  #
  # Ingest and create default set of licenses
  #
  task :ingest_collection_metadata => :environment do
    dir = ENV['dir'] unless ENV['dir'].nil?

    if (dir.nil?) || (!Dir.exists?(dir))
      if dir.nil?
        puts "No directory specified."
      else
        puts "Directory #{dir} does not exist."
      end
      puts "Usage: rake fedora:ingest_collection_metadata dir=<folder>"
      exit 1
    end

    Dir.glob(dir + '/**/*.n3') { |n3|
      coll_name = File.basename(n3, ".n3")
      create_collection_from_file(n3, coll_name)
    }
  end


  def ingest_corpus(corpus_dir, num_spec=:all, shuffle=false, annotations=true)

    label = "Ingesting...\n"
    label += "   corpus:      #{corpus_dir}\n"
    label += "   amount:      #{num_spec}\n"
    label += "   random:      #{shuffle}\n"
    label += "   annotations: #{annotations}"
    puts label

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

    puts "Ingesting #{num} file#{(num==1) ? '' : 's'} of #{rdf_files.size}"
    errors = {}
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
    unless rdf_file.to_s =~ /metadata/ # HCSVLAB-441
      raise ArgumentError, "#{rdf_file} does not appear to be a metadata file - at least, it's name doesn't say 'metadata'"
    end
    puts "#{Time.new.to_s} - Ingesting item: " + rdf_file.to_s
    STDOUT.flush
    item = create_item_from_file(corpus_dir, rdf_file)
    look_for_annotations(item, rdf_file) if annotations
    look_for_documents(item, corpus_dir, rdf_file)
    item.save!

#    if Collection.where(short_name: item.collection).count == 0
#      create_collection(item.collection.first, corpus_dir)
#    end

    # Msg to fedora.apim.update
    begin
      client = Stomp::Client.open "stomp://localhost:61613"
      client.publish('/queue/fedora.apim.update', "<xml><title type=\"text\">finishedWork</title><content type=\"text\">Fedora worker has finished with #{item.pid}</content><summary type=\"text\">#{item.pid}</summary> </xml>")
      client.close
    rescue Exception => msg 
      puts "Error sending message via stomp: #{msg}"
    end
    return item.pid
  end


  def reindex_item(item, stomp_client)
    puts "Reindexing item: " + item.id
    item.update_index
    stomp_client.publish('/queue/hcsvlab.solr.worker', "index #{item.id}")
  end


  def reindex_item_by_id(item_id, stomp_client)
    reindex_item(Item.find(item_id), stomp_client)
  end


  def report_results(label, corpus_dir, successes, errors)
    logfile = "log/ingest_#{File.basename(corpus_dir)}.log"
    logstream = File.open(logfile, "w")

    message = "Successfully ingested #{successes.size} Item#{successes.size==1 ? '' : 's'}"
    message += ", and rejected #{errors.size} Item#{errors.size==1 ? '' : 's'}" unless errors.empty?
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
    return true if string =~ (/(true|t|yes|y|1)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\", should be \"true\" or \"false\"")
  end

  def find_corpus_items(corpus)
    response = @solr.get 'select', :params => {:q => 'HCSvLab_collection_facet:' + corpus,
                                               :rows => 2147483647}
    response['response']['docs']
  end

end
