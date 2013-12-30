module Item::DownloadItemsHelper
  class DownloadItemsAsArchive
    include Blacklight::Configurable
    include Blacklight::SolrHelper
    include ActiveSupport::Rescuable
    include Hydra::Controller::ControllerBehavior

    FIXNUM_MAX = 2147483647
    #
    # Class variables for information about Solr
    #
    @@solr_config = nil
    @@solr = nil

    # Indicate Hydra to add access control to the SOLR requests
    self.solr_search_params_logic += [:add_access_controls_to_solr_params]
    self.solr_search_params_logic += [:exclude_unwanted_models]

    #
    #
    #
    def initialize (current_user = nil, current_ability = nil)
      @current_user = current_user
      @current_ability = current_ability
    end

    #
    #
    #
    def createAndRetrieveZipPath(itemsId, &block)
      # get_zip_with_documents_and_metadata(itemsId, &block)
      get_zip_with_documents_and_metadata_powered(itemsId)
    end

    #
    #
    #
    def createAndRetrieveWarcPath(itemsId, url, &block)
      get_warc_with_documents_and_metadata(itemsId, url, &block)
    end

    private

    #
    # Creates a ZIP file containing all the documents and metadata for the items listed in 'itemsId'.
    # The returned format respect the BagIt format (http://en.wikipedia.org/wiki/BagIt)
    #
    def get_zip_with_documents_and_metadata(itemsId, &block)
      if (!itemsId.nil? and !itemsId.empty?)
        begin

          timeStart = Time.now

          validatedIds = verifyItemsPermissions(itemsId)

          timeEnd = Time.now

          logger.debug "****************** Verify: #{timeEnd.to_f - timeStart.to_f}"

          valids = validatedIds[:valids]
          invalids = validatedIds[:invalids]

          timeStart = Time.now

          fileNamesByItem = get_documents_path(valids)
          timeEnd = Time.now

          logger.debug "****************** Doc path: #{timeEnd.to_f - timeStart.to_f}"

          digest_filename = Digest::MD5.hexdigest(valids.inspect.to_s)
          bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
          Dir.mkdir bagit_path

          # make a new bag at base_path
          bag = BagIt::Bag.new bagit_path

          timeStart = Time.now
          # add items metadata to the bag
          add_items_metadata_to_the_bag(fileNamesByItem, bag, &block)
          timeEnd = Time.now
          logger.debug "****************** Metadata: #{timeEnd.to_f - timeStart.to_f}"

          timeStart = Time.now
          # add items documents to the bag
          add_items_documents_to_the_bag(fileNamesByItem, bag)
          timeEnd = Time.now
          logger.debug "****************** doc files: #{timeEnd.to_f - timeStart.to_f}"

          # Add Log File
          logJsonText = {}
          logJsonText[:successful] = valids.length
          logJsonText[:unsuccessful] = invalids.length
          logJsonText[:unsuccessful_items] = invalids
          bag.add_file("log.json") do |io|
            io.puts logJsonText.to_json
          end

          timeStart = Time.now
          # generate the manifest and tagmanifest files
          bag.manifest!
          timeEnd = Time.now
          logger.debug "****************** bagit manifest: #{timeEnd.to_f - timeStart.to_f}"

          zip_path = "#{Rails.root.join("tmp", "#{digest_filename}.tmp")}"
          zip_file = File.new(zip_path, 'a+')
          ZipBuilder.build_zip(zip_file, Dir["#{bagit_path}/*"])

          zip_path
        ensure
          zip_file.close if !zip_file.nil?
          FileUtils.rm_rf bagit_path if !bagit_path.nil?
        end
      end
    end

    #
    # Creates a WARC file containing all the documents and metadata for the items listed in 'itemsId'.
    #
    def get_warc_with_documents_and_metadata(itemsId, url, &block)
      if (!itemsId.nil? and !itemsId.empty?)
        begin
          validatedIds = verifyItemsPermissions(itemsId)

          valids = validatedIds[:valids]
          invalids = validatedIds[:invalids]

          fileNamesByItem = get_documents_path(valids)

          digest_filename = Digest::MD5.hexdigest(valids.inspect.to_s)
          archive_path = "#{Rails.root.join("tmp", "#{digest_filename}.warc")}"
          logger.debug "WARC path is #{archive_path}"
          warc = WARCWriter.new(archive_path)

          warc.add_warcinfo(url, url)

          base_url = url.sub(/item_lists.*/, "")
          # add items metadata to the archive
          add_items_metadata_to_the_warc(fileNamesByItem, warc, base_url, &block)

          # add items documents to the archive
          add_items_documents_to_the_warc(fileNamesByItem, warc, base_url)

          # Add Log File
          logJsonText = {}
          logJsonText[:successful] = valids.length
          logJsonText[:unsuccessful] = invalids.length
          logJsonText[:unsuccessful_items] = invalids
          warc.add_record_from_string({}, logJsonText.to_json)

          archive_path
        ensure
          warc.close
        end

      end
    end

    def verifyItemsPermissions(itemsId, batch_group=50)
      valids = []
      invalids = []

      itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|
        # create disjunction condition with the items Ids
        condition = groupOfItemsId.map{|itemId| "id:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

        params = {}
        params[:q] = condition
        params[:rows] = FIXNUM_MAX

        (response, document_list) = get_search_results params
        valids += document_list.map{|aDoc| aDoc.id}.flatten
        invalids += groupOfItemsId - valids

      end

      {valids: valids, invalids: invalids}
    end

    def current_user
      @current_user
    end

    def current_ability
      @current_ability
    end



    #
    # =========================================================================
    # Constructing a 'BagIt' format bag
    # =========================================================================
    #

    #
    # This method will add all the documents listed in 'fileNamesByItem' to the 'bag'
    #
    # fileNamesByItem = Hash structure containing the items id as key and the list of files as value
    #                   Example:
    #                           {"hcsvlab:1003"=>{handle: "handle1", files:["full_path1, full_path2, .."]} ,
    #                            "hcsvlab:1034"=>{handle: "handle2", files:["full_path4, full_path5, .."]}}
    # bag = BagIt::Bag object
    #
    def add_items_documents_to_the_bag(fileNamesByItem, bag)

      fileNamesByItem.each_pair do |itemId, info|
        filenames = info[:files]
        handle = (info[:handle].nil?)? itemId.gsub(":", "_") : info[:handle]

        filenames.each do |file|
          if (File.exist?(file))
            title = file.split('/').last
            # make a new file
            # bag.add_file("#{handle}/#{title}") do |io|
            #   io.puts IO.read(file)
            # end
            bag.add_file_link("#{handle}/#{title}", file)
          end
        end
      end
    end

    #
    # This method will add each item metadata for the items listed in 'fileNamesByItem' to the 'bag'
    # It will also modify the parameter 'fileNamesByItem' to set the item handle
    #
    # fileNamesByItem = Hash structure containing the items id as key and the list of files as value
    #                   Example:
    #                           {"hcsvlab:1003"=>{handle: "handle1", files:["full_path1, full_path2, .."]} ,
    #                            "hcsvlab:1034"=>{handle: "handle2", files:["full_path4, full_path5, .."]}}
    # bag = BagIt::Bag object
    #
    def add_items_metadata_to_the_bag(fileNamesByItem, bag, batch_group = 50, &block)
      itemsId = fileNamesByItem.keys
      itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|
        # create disjunction condition with the items Ids
        condition = groupOfItemsId.map{|itemId| "id:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

        params = {}
        params[:q] = condition
        params[:rows] = FIXNUM_MAX

        (response, document_list) = get_search_results params
        document_list.each do |aDoc|
          handle = aDoc['handle'].gsub(":", "_")
          itemId = aDoc['id']
          fileNamesByItem[itemId][:handle] = handle

          # Render the view as JSON
          itemMetadata = block.call aDoc

          bag.add_file("#{handle}/#{handle}-metadata.json") do |io|
            io.puts itemMetadata
          end
        end
      end
    end
    #
    # End of Constructing a 'BagIt' format bag
    # -------------------------------------------------------------------------
    #



    #
    # =========================================================================
    # Constructing a WARC file
    # =========================================================================
    #

    #
    # This method will add all the documents listed in 'fileNamesByItem' to the WARC
    #
    # fileNamesByItem = Hash structure containing the items id as key and the list of files as value
    #                   Example:
    #                           {"hcsvlab:1003"=>{handle: "handle1", files:["full_path1, full_path2, .."]} ,
    #                            "hcsvlab:1034"=>{handle: "handle2", files:["full_path4, full_path5, .."]}}
    # warc = A WARCWriter which has been opened for write.
    #
    def add_items_documents_to_the_warc(fileNamesByItem, warc, base_url)

      item_metadata_added = Array.new
      fileNamesByItem.each_pair do |itemId, info|
        filenames = info[:files]
        metadata  = info[:metadata] || {}

        handle = (info[:handle].nil?)? itemId.gsub(":", "_") : info[:handle]

        filenames.each do |file|
          if (File.exist?(file))
            title = file.split('/').last
            # make a new file
            metadata = {} if item_metadata_added.include? itemId # don't add item metadata if already added for another document
            warc.add_record_from_file(metadata.merge({"WARC-Type" => "response", "WARC-Record-ID" => "#{base_url}catalog/#{itemId}/document/#{title}"}), file)
            item_metadata_added.push itemId
          else
            logger.warn("Document file #{file} does not exist (part of Item #{itemId}")
          end
        end
      end
    end

    #
    # This method will add each item metadata for the items listed in 'fileNamesByItem' into
    # fileNamesByItem under the [:metadata] key.
    # It will also modify the parameter 'fileNamesByItem' to set the item handle
    #
    # fileNamesByItem = Hash structure containing the items id as key and the list of files as value
    #                   Example:
    #                           {"hcsvlab:1003"=>{handle: "handle1", files:["full_path1, full_path2, .."]} ,
    #                            "hcsvlab:1034"=>{handle: "handle2", files:["full_path4, full_path5, .."]}}
    # warc = A WARCWriter which has been opened for write.
    #
    def add_items_metadata_to_the_warc(fileNamesByItem, warc, base_url, batch_group = 50, &block)
      itemsId = fileNamesByItem.keys
      itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|
        # create disjunction condition with the items Ids
        condition = groupOfItemsId.map{|itemId| "id:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

        params = {}
        params[:q] = condition
        params[:rows] = FIXNUM_MAX

        (response, document_list) = get_search_results params
        document_list.each do |aDoc|
          handle = aDoc['handle'].gsub(":", "_")
          itemId = aDoc['id']
          fileNamesByItem[itemId][:handle] = handle

          # Render the view as JSON
          itemMetadata = block.call aDoc
          fileNamesByItem[itemId][:metadata] = itemMetadata
        end
      end
    end

    #
    # End of Constructing a WARC file
    # -------------------------------------------------------------------------
    #

    #
    # Retrieves the path for the documents which belong to the items listed in 'itemsId'
    #
    def get_documents_path(itemsId, batch_group = 50)
      bench_start = Time.now

      # In this first step we will collect the file location for the documents belonging to the requested items
      fileNamesByItem = {}
      itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|

        # create disjunction condition with the items Ids
        condition = groupOfItemsId.map{|itemId| "item_id_tesim:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

        # query SOLR restricting to retrieve only the object profile field
        objectsProfile = Document.find_with_conditions(condition, {fl:"object_profile_ssm, item_id_tesim", rows:FIXNUM_MAX})

        # Parse every object profile and extract the file location
        objectsProfile.each do |anObjectProfile|
          itemId = anObjectProfile["item_id_tesim"].first
          fileNamesByItem[itemId] = {handle: nil, files:[]} if fileNamesByItem[itemId].nil?

          jsonString = anObjectProfile["object_profile_ssm"].first
          json = JSON.parse(jsonString)

          filename = json["datastreams"]["CONTENT1"]["dsLocation"]
          fileNamesByItem[itemId][:files] << filename.to_s.gsub("file://", "")
        end
      end

      Rails.logger.debug("Time for retrieve documents path for #{itemsId.length} items: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

      return fileNamesByItem
    end

    #
    # blacklight uses this method to get the SOLR connection.
    def blacklight_solr
      get_solr_connection
      @@solr
    end

    #
    # Initialise the connection to Solr
    #
    def get_solr_connection
      if @@solr_config.nil?
        @@solr_config = Blacklight.solr_config
        @@solr        = RSolr.connect(@@solr_config)
      end
    end

    #####################################################################################################################################
    # THIS CODE IS A PROOF OF CONCEPT FOR IMPROVING THE PERFORMANCE ON DOWNLOADING ITEMS IN ZIP FORMAT
    # THIS RELIES IN THE FACT THAT THE METADATA IS STORED IN THE BL-CORE.
    # IN CASE THE PERFORMANCE OF THIS IS ACCEPTABLE, THEN WE SHOULD TIDE UP THE CODE AND REPLACE THE PREVIOUS IMPLEMENTATION

    #
    # Creates a ZIP file containing all the documents and metadata for the items listed in 'itemsId'.
    # The returned format respect the BagIt format (http://en.wikipedia.org/wiki/BagIt)
    #
    def get_zip_with_documents_and_metadata_powered(itemsId)
      if (!itemsId.nil? and !itemsId.empty?)
        begin

          timeStart = Time.now

          info = verifyItemsPermissionsAndExtractMetadata(itemsId)

          timeEnd = Time.now

          logger.debug "****************** Verify: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** Verify: #{timeEnd.to_f - timeStart.to_f}"

          valids = info[:valids]
          invalids = info[:invalids]
          metadata = info[:metadata]

          timeStart = Time.now

          fileNamesByItem = {}
          metadata.each_pair do |key, value|
            handle = value[:metadata]['metadata']['handle'].gsub(':', '_')
            files = value[:files].map {|filename| filename.to_s.gsub("file://", "")}
            fileNamesByItem[key] = {handle: handle, files: files}
          end

          timeEnd = Time.now

          logger.debug "****************** Doc path: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** Doc path: #{timeEnd.to_f - timeStart.to_f}"

          digest_filename = Digest::MD5.hexdigest(valids.inspect.to_s)
          bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
          Dir.mkdir bagit_path

          # make a new bag at base_path
          bag = BagIt::Bag.new bagit_path

          timeStart = Time.now
          # add items metadata to the bag
          add_items_metadata_to_the_bag_powered(metadata, bag)
          timeEnd = Time.now
          logger.debug "****************** Metadata: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** Metadata: #{timeEnd.to_f - timeStart.to_f}"

          timeStart = Time.now
          # add items documents to the bag
          add_items_documents_to_the_bag(fileNamesByItem, bag)
          timeEnd = Time.now
          logger.debug "****************** doc files: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** doc files: #{timeEnd.to_f - timeStart.to_f}"

          # Add Log File
          logJsonText = {}
          logJsonText[:successful] = valids.length
          logJsonText[:unsuccessful] = invalids.length
          logJsonText[:unsuccessful_items] = invalids
          bag.add_file("log.json") do |io|
            io.puts logJsonText.to_json
          end

          timeStart = Time.now
          # generate the manifest and tagmanifest files
          bag.manifest!
          timeEnd = Time.now
          logger.debug "****************** bagit manifest: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** bagit manifest: #{timeEnd.to_f - timeStart.to_f}"

          timeStart = Time.now
          zip_path = "#{Rails.root.join("tmp", "#{digest_filename}.tmp")}"
          zip_file = File.new(zip_path, 'a+')
          ZipBuilder.build_zip(zip_file, Dir["#{bagit_path}/*"])
          timeEnd = Time.now
          logger.debug "****************** building zip: #{timeEnd.to_f - timeStart.to_f}"
          #puts "****************** building zip: #{timeEnd.to_f - timeStart.to_f}"

          zip_path
        ensure
          zip_file.close if !zip_file.nil?
          FileUtils.rm_rf bagit_path if !bagit_path.nil?
        end
      end
    end

    #
    #
    #
    def verifyItemsPermissionsAndExtractMetadata(itemsId,batch_group=50)
      valids = []
      invalids = []
      metadata = {}

      itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|
        # create disjunction condition with the items Ids
        condition = groupOfItemsId.map{|itemId| "id:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

        params = {}
        params[:q] = condition
        params[:rows] = FIXNUM_MAX

        (response, document_list) = get_search_results params
        document_list.each do |aDoc|
          valids << aDoc[:id]
          begin
            jsonMetadata = JSON.parse(aDoc['json_metadata'])
          rescue
            puts "******** #{aDoc[:id]}"
          end
          metadata[aDoc[:id]] = {}
          metadata[aDoc[:id]][:files] = jsonMetadata['documentsLocations'].clone.values.flatten
          jsonMetadata.delete('documentsLocations')
          metadata[aDoc[:id]][:metadata] = jsonMetadata
        end



        #valids += document_list.map{|aDoc| aDoc.id}.flatten
        invalids += groupOfItemsId - valids

      end

      {valids: valids, invalids: invalids, metadata: metadata}


    end

    #
    #
    #
    def add_items_metadata_to_the_bag_powered(metadata, bag)
      metadata.each_pair do |key, value|
        # Render the view as JSON
        itemMetadata = value[:metadata]
        handle = itemMetadata['metadata']['handle'].gsub(":", "_")

        bag.add_file("#{handle}/#{handle}-metadata.json") do |io|
          io.puts itemMetadata
        end

      end
    end

    ########################################################################################################################################
  end
end