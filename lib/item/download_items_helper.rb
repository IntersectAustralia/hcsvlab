module Item::DownloadItemsHelper

  def generate_aspera_transfer_spec(item_handles)
    # create directory for storing the temporary files generated for item metadata and item log
    metadata_dir = Dir.mkdir(nil, Rails.application.config.aspera_temp_path)
    request = DownloadItemsInFormat.new(current_user, current_ability).create_aspera_transfer_spec(item_handles, metadata_dir)
    render :json => {request: request}
  rescue => e
    Rails.logger.error(e.message + "\n " + e.backtrace.join("\n "))
    render :json => {error: "Internal Server Error"}.to_json, :status => 500
  end

  def download_as_zip(itemHandles, file_name)
    begin
      cookies.delete("download_finished")

      bench_start = Time.now

      # Creates a ZIP file containing the documents and item's metadata
      zip_path = DownloadItemsInFormat.new(current_user, current_ability).createAndRetrieveZipPath(itemHandles)

      # Sends the zipped file
      send_data IO.read(zip_path), :type => 'application/zip',
                :disposition => 'attachment',
                :filename => file_name

      Rails.logger.debug("Time for downloading metadata and documents for #{itemHandles.length} items: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
      cookies["download_finished"] = {value:"true", expires: 1.minute.from_now}
      return

    rescue Exception => e
      Rails.logger.error(e.message + "\n " + e.backtrace.join("\n "))
    ensure
      # Ensure zipped file is removed
      FileUtils.rm zip_path if !zip_path.nil?
    end
    respond_to do |format|
      format.html {
        flash[:error] = "Sorry, an unexpected error occur."
        redirect_to @item_list and return
      }
      format.any { render :json => {:error => "Internal Server Error"}.to_json, :status => 500 }
    end
  end


  def download_as_warc(itemHandles, file_name)
    begin
      cookies.delete("download_finished")

      bench_start = Time.now

      dont_show = Set.new(Item.development_only_fields)

      # Creates a WARC file containing the documents and item's metadata
      archive_path = DownloadItemsInFormat.new(current_user, current_ability).createAndRetrieveWarcPath(itemHandles, request.original_url) do |aDoc|
        @document = aDoc
        itemMetadata = {}
        keys = aDoc.keys
        aDoc.keys.each { |key|
          itemMetadata[key] = aDoc[key].join(', ') unless dont_show.include?(key)
        }
        itemMetadata
      end

      # Sends the archive file
      send_data IO.read(archive_path), :type => 'application/warc',
                :disposition => 'attachment',
                :filename => file_name

      Rails.logger.debug("Time for downloading metadata and documents for #{itemHandles.length} items: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
      cookies["download_finished"] = {value:"true", expires: 1.minute.from_now}
      return

    rescue Exception => e
      Rails.logger.error(e.message + "\n " + e.backtrace.join("\n "))
    ensure
      # Ensure archive file is removed
      FileUtils.rm archive_path if !archive_path.nil?
    end
    respond_to do |format|
      format.html {
        flash[:error] = "Sorry, an unexpected error occur."
        redirect_to @item_list and return
      }
      format.any { render :json => {:error => "Internal Server Error"}.to_json, :status => 500 }
    end
  end

  class DownloadItemsInFormat
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


    def create_aspera_transfer_spec(item_handles, metadata_dir)
      get_aspera_transfer_spec_for_documents_and_metadata(item_handles, metadata_dir)
    end

    #
    #
    #
    def createAndRetrieveZipPath(itemHandles)
      get_zip_with_documents_and_metadata_powered(itemHandles)
    end

    #
    #
    #
    def createAndRetrieveWarcPath(itemHandles, url, &block)
      get_warc_with_documents_and_metadata(itemHandles, url, &block)
    end

    private

    def get_aspera_transfer_spec_for_documents_and_metadata(item_handles, transfer_dir)
      return {} unless items_handles.empty?

      result = verify_items_permissions_and_extract_metadata(item_handles)

      # generate item files, metadata files and log files
      item_files = create_items_files(result)
      metadata_files = create_items_metadata_files(result[:metadata], transfer_dir)
      log_file = create_items_log_file(result, transfer_dir)

      request_apsera_transfer_spec([item_files, metadata_files, log_file].flatten)
    rescue => e
      FileUtils.rm_rf transfer_dir if Dir.exists? transfer_dir
      raise e
    end

    def create_items_files(result)
      get_filenames_from_item_results(result).map do |key, value|
        dir = value[:handle]
        value[:files].map { |file| { dir: dir, file: file } }
      end.flatten
    end

    def create_items_metadata_files(items_metadata, transfer_dir)
      items_metadata.map do |key, value|
        item_metadata = value[:metadata]
        handle = item_metadata['metadata']['handle'].gsub(":", "_")
        metadata_file = File.join(transfer_dir, "#{handle}-metadata.json")
        File.open(metadata_file , 'w+') do |f|
          f.write(itemMetadata.to_json)
        end
        { dir: handle, file: metadata_file }
      end
    end

    def create_items_log_file(result, transfer_dir)
      log_file = File.join(transfer_dir, 'log.json')
      File.open(log_file) do |f|
        f.write(generate_json_log(result[:valids], result[:invalids]))
      end
      { dir: '.', file: log_file }
    end

    def request_aspera_transfer_spec(requested_files)
      source_root = Rails.application.config.aspera_source_root
      source_paths = requested_files.map {|file| { source: file[:file], destination: "#{file[:dir]}/#{file}" }}
      download_request = {
        transfer_requests: [
          transfer_request: {
            source_root: source_root,
            paths: source_paths
          }
        ]
      }
      node_api = NodeAPI.new(Rails.application.config.aspera_nodeapi_config)
      result = node_api.download_setup(download_request)
      result
    end

    #
    # Creates a WARC file containing all the documents and metadata for the items listed in 'itemHandles'.
    #
    def get_warc_with_documents_and_metadata(item_handles, url, &block)
      if item_handles.present?
        begin
          result = verify_items_permissions_and_extract_metadata(item_handles)

          fileNamesByItem = get_filenames_from_item_results(result)

          digest_filename = Digest::MD5.hexdigest(result[:valids].inspect.to_s)
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
          warc.add_record_from_string({}, generate_json_log(result[:valids], result[:invalids]))

          archive_path
        ensure
          warc.close
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
    def get_zip_with_documents_and_metadata_powered(item_handles)
      if item_handles.present?
        begin
          result = verify_items_permissions_and_extract_metadata(item_handles)

          fileNamesByItem = get_filenames_from_item_results(result)

          digest_filename = Digest::MD5.hexdigest(result[:valids].inspect.to_s)
          bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
          Dir.mkdir bagit_path

          # make a new bag at base_path
          bag = BagIt::Bag.new bagit_path

          # add items metadata to the bag
          add_items_metadata_to_the_bag_powered(result[:metadata], bag)

          # add items documents to the bag
          add_items_documents_to_the_bag(fileNamesByItem, bag)

          # Add Log File
          bag.add_file("log.json") do |io|
            io.puts generate_json_log(result[:valids], result[:invalids])
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
    #
    #
    def verify_items_permissions_and_extract_metadata(item_handles, batch_group=2500)
      valids = []
      invalids = []
      metadata = {}

      licence_ids = UserLicenceAgreement.where(user_id: @current_user.id).pluck('distinct licence_id')
      t = Collection.arel_table
      collection_ids = Collection.where(t[:licence_id].in(licence_ids).or(t[:owner_id].eq(current_user.id))).pluck(:id)

      item_handles.in_groups_of(batch_group, false) do |item_handle_group|
        query = Item.indexed.where(collection_id: collection_ids, handle: item_handle_group).select([:id, :handle, :json_metadata])
        valids = query.collect(&:handle)
        query.each do |item|
          begin
            json = JSON.parse(item.json_metadata)
          rescue
            Rails.logger.debug("Error parsing json_metadata for document #{item.id}")
          end
          metadata[item.id] = {}
          metadata[item.id][:files] = json['documentsLocations'].clone.values.flatten
          json.delete('documentsLocations')
          metadata[item.id][:metadata] = json
          item.documents.each do |doc|
            DocumentAudit.create(document: doc, user: current_user)
          end
        end

        invalids += item_handle_group - valids

      end

      {valids: valids, invalids: invalids, metadata: metadata}
    end

    def get_filenames_from_item_results(result)
      metadata = result[:metadata]

      fileNamesByItem = {}
      metadata.each_pair do |key, value|
        handle = value[:metadata]['metadata']['handle'].gsub(':', '_')
        files = value[:files].map {|filename| filename.to_s.gsub(/(^file:(\/)+)/, "/")}
        fileNamesByItem[key] = {handle: handle, files: files}
      end

      fileNamesByItem
    end

    def generate_json_log(valids, invalids)
      json_log = {}
      json_log[:successful] = valids.length
      json_log[:unsuccessful] = invalids.length
      json_log[:unsuccessful_items] = invalids
      json_log.to_json
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
