module Item::DownloadItemsHelper
  class DownloadItemsInZipFormat
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
      get_zip_with_documents_and_metadata(itemsId, &block)
    end

    private

    #
    # Creates a ZIP file containing all the documents and metadata for the items listed in 'itemsId'.
    # The returned format respect the BagIt format (http://en.wikipedia.org/wiki/BagIt)
    #
    def get_zip_with_documents_and_metadata(itemsId, &block)
      if (!itemsId.nil? and !itemsId.empty?)
        begin

          validatedIds = verifyItemsPermissions(itemsId)

          valids = validatedIds[:valids]
          invalids = validatedIds[:invalids]

          fileNamesByItem = get_documents_path(valids)

          digest_filename = Digest::MD5.hexdigest(valids.inspect.to_s)
          bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
          Dir.mkdir bagit_path

          # make a new bag at base_path
          bag = BagIt::Bag.new bagit_path

          # add items metadata to the bag
          add_items_metadata_to_the_bag(fileNamesByItem, bag, &block)

          # add items documents to the bag
          add_items_documents_to_the_bag(fileNamesByItem, bag)

          # Add Log File
          bag.add_file("log.json") do |io|
            io.puts("Successful: #{valids.length} items.")
            io.puts("")
            io.puts("Unsuccessful: #{invalids.length} items.")

            invalids.each do |invalidItemId|
              io.puts("       #{invalidItemId.to_s}")
            end
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
            bag.add_file("#{handle}/#{title}") do |io|
              io.puts IO.read(file)
            end
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


  end
end