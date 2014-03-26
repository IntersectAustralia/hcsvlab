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
    def createAndRetrieveZipPath(itemHandles, &block)
      get_zip_with_documents_and_metadata_powered(itemHandles)
    end

    #
    #
    #
    def createAndRetrieveWarcPath(itemHandles, url, &block)
      get_warc_with_documents_and_metadata(itemHandles, url, &block)
    end

    private

    #
    # Creates a WARC file containing all the documents and metadata for the items listed in 'itemHandles'.
    #
    def get_warc_with_documents_and_metadata(itemHandles, url, &block)
      if (!itemHandles.nil? and !itemHandles.empty?)
        begin
          info = verifyItemsPermissionsAndExtractMetadata(itemHandles)

          valids = info[:valids]
          invalids = info[:invalids]
          metadata = info[:metadata]

          fileNamesByItem = {}
          metadata.each_pair do |key, value|
            handle = value[:metadata]['metadata']['handle']
            files = value[:files].map {|filename| filename.to_s.gsub(/(^file:(\/)+)/, "/")}
            fileNamesByItem[key] = {handle: handle, files: files}
          end

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
            bag.add_file_link("#{handle}/#{title}", file)
          end
        end
      end
    end

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

      fileNamesByItem.each_pair do |itemId, info|
        filenames = info[:files]
        metadata  = info[:metadata] || {}

        indexable_text_document = (filenames.select {|f| f.include? "-plain.txt"}).empty? ? "" : (filenames.select {|f| f.include? "-plain.txt"})[0]
        collectionName = info[:handle].split(':').first
        itemIdentifier = info[:handle].split(':').last
        if File.exist?(indexable_text_document)
          title = indexable_text_document.split('/').last
          warc.add_record_from_file(metadata.merge({"WARC-Type" => "response", "WARC-Record-ID" => "#{base_url}catalog/#{collectionName}/#{itemIdentifier}/document/#{title}"}), indexable_text_document)
        elsif indexable_text_document.blank?
          logger.warn("No primary (plaintext) document found for Item #{itemId}")
          warc.add_record_metadata(metadata.merge({"WARC-Type" => "response", "WARC-Record-ID" => "#{base_url}catalog/#{collectionName}/#{itemIdentifier}"}))
        else
          logger.warn("Document file #{indexable_text_document} does not exist (part of Item #{itemId}")
          warc.add_record_metadata(metadata.merge({"WARC-Type" => "response", "WARC-Record-ID" => "#{base_url}catalog/#{collectionName}/#{itemIdentifier}"}))
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
          handle = aDoc['handle']
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
    # Creates a ZIP file containing all the documents and metadata for the items listed in 'itemHandles'.
    # The returned format respect the BagIt format (http://en.wikipedia.org/wiki/BagIt)
    #
    def get_zip_with_documents_and_metadata_powered(itemHandles)
      if (!itemHandles.nil? and !itemHandles.empty?)
        begin

          info = verifyItemsPermissionsAndExtractMetadata(itemHandles)

          valids = info[:valids]
          invalids = info[:invalids]
          metadata = info[:metadata]

          fileNamesByItem = {}
          metadata.each_pair do |key, value|
            handle = value[:metadata]['metadata']['handle'].gsub(':', '_')
            files = value[:files].map {|filename| filename.to_s.gsub(/(^file:(\/)+)/, "/")}
            fileNamesByItem[key] = {handle: handle, files: files}
          end

          digest_filename = Digest::MD5.hexdigest(valids.inspect.to_s)
          bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
          Dir.mkdir bagit_path

          # make a new bag at base_path
          bag = BagIt::Bag.new bagit_path

          # add items metadata to the bag
          add_items_metadata_to_the_bag_powered(metadata, bag)

          # add items documents to the bag
          add_items_documents_to_the_bag(fileNamesByItem, bag)

          # Add Log File
          logJsonText = {}
          logJsonText[:successful] = valids.length
          logJsonText[:unsuccessful] = invalids.length
          logJsonText[:unsuccessful_items] = invalids
          bag.add_file("log.json") do |io|
            io.puts logJsonText.to_json
          end

          # generate the manifest and tagmanifest files
          bag.manifest!

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
    #
    #
    def verifyItemsPermissionsAndExtractMetadata(itemHandles,batch_group=50)
      valids = []
      invalids = []
      metadata = {}

      itemHandles.in_groups_of(batch_group, false) do |groupOfItemHandles|
        # create disjunction condition with the items Ids
        condition = groupOfItemHandles.map{|itemHandle| "handle:\"#{itemHandle.gsub(":", "\:")}\""}.join(" OR ")

        params = {}
        params[:q] = condition
        params[:rows] = FIXNUM_MAX

        (response, document_list) = get_search_results params
        document_list.each do |aDoc|
          valids << aDoc[:handle]
          begin
            jsonMetadata = JSON.parse(aDoc['json_metadata'])
          rescue
            Rails.logger.debug("Error parsing json_metadata for document #{aDoc[:id]}")
          end
          metadata[aDoc[:id]] = {}
          metadata[aDoc[:id]][:files] = jsonMetadata['documentsLocations'].clone.values.flatten
          jsonMetadata.delete('documentsLocations')
          metadata[aDoc[:id]][:metadata] = jsonMetadata
        end

        invalids += groupOfItemHandles - valids

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
          io.puts itemMetadata.to_json
        end

      end
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

    #
    #
    #
    def current_user
      @current_user
    end

    #
    #
    #
    def current_ability
      @current_ability
    end
  end
end