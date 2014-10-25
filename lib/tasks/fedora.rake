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

    logger.info "rake fedora:ingest_one #{corpus_rdf}"
    pid = ingest_one(File.dirname(corpus_rdf), corpus_rdf)
    puts "Ingested item #{pid}" if Rails.env.test?

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

    logger.info "rake fedora:ingest corpus=#{corpus_dir} amount=#{num_spec} random=#{random} annotations=#{annotations}"
    ingest_corpus(corpus_dir, num_spec, random, annotations)
  end

  #
  # Clear everything out of the system
  #
  task :clear => :environment do

    logger.info "rake fedora:clear"

    Document.delete_all
    Item.delete_all
    Collection.delete_all
    CollectionList.delete_all

    # clear Solr
    uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

    req = Net::HTTP::Post.new(uri)
    req.body = '<delete><query>*:*</query></delete>'

    req.content_type = "text/xml; charset=utf-8"
    req.body.force_encoding("UTF-8")
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    # Clear Sesame
    server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
    repositories = server.repositories
    repositories.each_key do |repositoryName|
      if (!"SYSTEM".eql? repositoryName)
        server.delete(repositories[repositoryName].path)
      end
    end

  end


  #
  # Clear one corpus (given as corpus=<corpus-name>) out of the system
  #
  task :clear_corpus => :environment do

    corpus = ENV['corpus']

    if corpus.nil?
      puts "Usage: rake fedora:clear_corpus corpus=<corpus name>"
      exit 1
    end

    logger.info "rake fedora:clear_corpus corpus=#{corpus}"

    collection = Collection.find_by_name(corpus)
    Document.where(item_id: Item.where(collection_id: collection)).delete_all
    Item.where(collection_id: collection).delete_all
    collection.destroy

    # clear Solr
    uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

    req = Net::HTTP::Post.new(uri)
    req.body = "<delete><query>handle:#{corpus}\\:*</query></delete>"

    req.content_type = "text/xml; charset=utf-8"
    req.body.force_encoding("UTF-8")
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    # Clear all metadata and annotations from the triple store
    server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
    repository = server.repository(corpus)
    repository.clear if repository.present?

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

    logger.info "rake fedora:reindex_one item=#{item_id}"

    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    reindex_item_to_solr(item_id, stomp_client)
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

    logger.info "rake fedora:reindex_corpus corpus=#{corpus}"

    objects = find_corpus_items corpus

    logger.info "Reindexing #{objects.count} Items"

    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    objects.each do |obj|
      reindex_item_to_solr(obj["id"], stomp_client)
    end
    stomp_client.close

  end

  # TODO
  # Consolidate cores by reindexing items found only in the ActiveFedora core
  #
  CHUNK_SIZE = 50
  task :consolidate_cores => :environment do
    solr_af_core = ActiveFedora::SolrService.instance.conn
    stomp_client = Stomp::Client.open "stomp://localhost:61613"

    corpus = ENV['corpus']
    if corpus.present?
      query = "has_model_ssim:info:fedora/afmodel:Item edit_access_group_ssim:#{corpus}-edit"
    else
      query = 'has_model_ssim:info:fedora/afmodel:Item'
    end

    fedora_response = solr_af_core.get 'select', :params => {:q => query}
    num = fedora_response["response"]["numFound"]
    chunks = (num/CHUNK_SIZE)+1
    start_row = 0
    chunks.times do |chunk|
      logger.info "Investigating item set " + (chunk+1).to_s + " of " + chunks.to_s
      fedora_response = solr_af_core.get 'select', :params => {:q => query, :fl => 'id', :sort => 'id asc', :start => start_row, :rows => CHUNK_SIZE}
      fedora_records = fedora_response["response"]["docs"].collect { |f| f["id"] }
      fq_query = "id:(" + fedora_records.collect { |item| item.sub(/:/, '\:') }.join(" OR ") +")"
      solr_reponse = @solr.get 'select', :params => {fq: fq_query, :fl => 'id', rows: CHUNK_SIZE}
      solr_records = solr_reponse["response"]["docs"].collect { |s| s["id"] }
      missing_ids = fedora_records - solr_records
      missing_ids.each do |missing_id|
        reindex_item_to_solr(missing_id, stomp_client)
      end
      start_row+=CHUNK_SIZE
    end
    stomp_client.close
  end

  #
  # Reindex the whole blinkin' lot
  #
  task :reindex_all => :environment do

    logger.info "rake fedora:reindex_all"

    response = @solr.get 'select', :params => {:q => ''}
    num = response["response"]["numFound"]

    logger.info "Reindexing all #{num} Items"

    stomp_client = Stomp::Client.open "stomp://localhost:61613"

    chunks = (num/CHUNK_SIZE)+1
    start_row = 0
    chunks.times do |chunk|
      response = @solr.get 'select', :params => {:fl => 'id', :sort => 'id asc', :start => start_row, :rows => CHUNK_SIZE}
      response["response"]["docs"].each do |doc|
        reindex_item_to_solr(doc["id"], stomp_client)
      end
      start_row+=CHUNK_SIZE
    end

    stomp_client.close

  end

  #
  # Ingest and create default set of licenses
  #
  task :ingest_licences => :environment do
    logger.info "rake fedora:ingest_licences"
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

    logger.info "rake fedora:ingest_collection_metadata dir=#{dir}"

    Dir.glob(dir + '/**/*.n3') { |n3|
      coll_name = File.basename(n3, ".n3")
      create_collection_from_file(n3, coll_name)
    }
  end


  #
  # Set up the default CollectionLists and License assignments
  #
  task :collection_setup => :environment do
    logger.info "rake fedora:collection_setup"

    licences = {}
    Licence.all.each { |licence|
      licences[licence.name] = licence
    }

    setup_collection_list("AUSNC", licences["AusNC Terms of Use"],
                          "ace", "art", "austlit", "braidedchannels", "cooee", "gcsause", "ice", "mitcheldelbridge", "monash")
    setup_collection_list("PARADISEC", licences["PARADISEC Conditions of Access"],
                          "paradisec", "eopas_test")
    Collection.assign_licence("austalk", licences["AusTalk Terms of Use"])
    Collection.assign_licence("avozes", licences["AVOZES Non-commercial (Academic) Licence"])
    Collection.assign_licence("clueweb", licences["ClueWeb Terms of Use"])
    Collection.assign_licence("pixar", licences["Creative Commons v3.0 BY-NC-SA"])
    Collection.assign_licence("rirusyd", licences["Creative Commons v3.0 BY-NC-SA"])
    Collection.assign_licence("mbep", licences["Creative Commons v3.0 BY-NC-SA"])
    Collection.assign_licence("jakartan_indonesian", licences["Creative Commons v3.0 BY-NC-SA"])
  end

  #
  # Check a corpus directory, given as an argument
  #
  task :check => :environment do

    corpus_dir = ENV['corpus'] unless ENV['corpus'].nil?

    if (corpus_dir.nil?) || (!Dir.exists?(corpus_dir))
      if corpus_dir.nil?
        puts "No corpus directory specified."
      else
        puts "Corpus directory #{corpus_dir} does not exist."
      end
      puts "Usage: rake fedora:check corpus=<corpus folder>"
      exit 1
    end

    logger.info "rake fedora:check corpus=#{corpus_dir}"
    check_corpus(corpus_dir)
  end

  #
  # Create a manifest for a collection outlining the collection name, item ids and document metadata
  #
  task :create_collection_manifest => :environment do
    corpus_dir = ENV['corpus'] unless ENV['corpus'].nil?

    if (corpus_dir.nil?) || (!Dir.exists?(corpus_dir))
      if corpus_dir.nil?
        puts "No corpus directory specified."
      else
        puts "Corpus directory #{corpus_dir} does not exist."
      end
      puts "Usage: rake fedora:create_collection_manifest corpus=<corpus folder>"
      exit 1
    end

    logger.info "rake fedora:create_collection_manifest corpus=#{corpus_dir}"
    create_collection_manifest(corpus_dir)
  end


  def ingest_corpus(corpus_dir, num_spec=:all, shuffle=false, annotations=true)

    label = "Ingesting...\n"
    label += "   corpus:      #{corpus_dir}\n"
    label += "   amount:      #{num_spec}\n"
    label += "   random:      #{shuffle}\n"
    label += "   annotations: #{annotations}"
    puts label

    check_and_create_manifest(corpus_dir)

    overall_start = Time.now

    manifest = JSON.parse(IO.read(File.join(corpus_dir, MANIFEST_FILE_NAME)))

    collection_name = manifest["collection_name"]
    collection = check_and_create_collection(collection_name, corpus_dir)

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
    endTime = Time.new
    logger.debug("Time for ingesting #{corpus_dir}: (#{'%.1f' % ((endTime.to_f - overall_start.to_f)*1000)}ms)")

  end

  def reindex_item_to_solr(item_id, stomp_client)
    logger.info "Reindexing item: #{item_id}"
    stomp_client.publish('/queue/hcsvlab.solr.worker', "index #{item_id}")
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
        handle = check_rdf_file(corpus_dir, rdf_file, index, rdf_files.size)
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


  def check_rdf_file(corpus_dir, rdf_file, index, limit)
    unless rdf_file.to_s =~ /metadata/ # HCSVLAB-441
      raise ArgumentError, "#{rdf_file} does not appear to be a metadata file - at least, it's name doesn't say 'metadata'"
    end
    logger.info "Checking file #{index} of #{limit}: #{rdf_file}"
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
    logger.warning("Didn't create CollectionList #{list_name}") if list.nil?
  end

  def send_solr_message(command, objectID)
    info("Fedora_Worker", "sending instruction to Solr_Worker: #{command} #{objectID}")
    publish :solr_worker, "#{command} #{objectID}"
    debug("Fedora_Worker", "Cache size: #{@@cache.size}")
    @@cache.each_pair { |key, value|
      debug("Fedora_Worker", "   @cache[#{key}] = #{value}")
    }
  end
end
