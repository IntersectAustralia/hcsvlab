class ItemListsController < ApplicationController
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include ItemMetadataHelper

  before_filter :authenticate_user!
  load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :itemList

  FIXNUM_MAX = 2147483647
  #
  # Class variables for information about Solr
  #
  @@solr_config = nil
  @@solr = nil

  def index
    if (session[:profiler])
      @profiler = session[:profiler]
      session.delete(:profiler)
    end
  end

  def show
    if (session[:profiler])
      @profiler = session[:profiler]
      session.delete(:profiler)
    end
    @response = @item_list.get_items(params[:page], params[:per_page])
    @document_list = @response["response"]["docs"]
    respond_to do |format|
      format.html { render :index }
      format.json
    end
    
  end
  
  def create
    if request.format == 'json' and request.post?
      name = params[:name]
      if (!name.nil? and !name.blank?) and (!params[:items].nil? and params[:items].is_a? Array)
        item_lists = current_user.item_lists.where(:name => name)
        if item_lists.empty?
          @item_list = ItemList.new(:name => name, :user_id => current_user.id)
          @item_list.save!
          new_item_list = true
        else
          @item_list = item_lists[0]
          new_item_list = false
        end
        ids = params[:items].collect { |x| File.basename(x) }
        addItemsResult = add_item_to_item_list(@item_list, ids)
        added_set = addItemsResult[:addedItems]
        if new_item_list
          @success_message = "#{added_set.count} items added to new item list #{@item_list.name}"
        else
          @success_message = "#{added_set.count} items added to existing item list #{@item_list.name}"
        end
      else
        err_message = "name parameter" if name.nil? or name.blank?
        err_message = "items parameter" if params[:items].nil?
        err_message = "name and items parameters" if (name.nil? or name.blank?) and params[:items].nil?
        err_message << " not found" if !err_message.nil?
        err_message = "items parameter not an array" if !params[:items].is_a? Array and err_message.nil?
        respond_to do |format|
          format.any { render :json => {:error => err_message}.to_json, :status => 400 }
        end
      end
    else
      if params[:all_items] == 'true'
        documents = @item_list.getAllItemsFromSearch(params[:query_all_params])
      else
        documents = params[:sel_document_ids].split(",")
      end
      if @item_list.save
        flash[:notice] = 'Item list created successfully'
        addItemsResult = add_item_to_item_list(@item_list, documents)
        session[:profiler] = addItemsResult[:profiler]
        redirect_to @item_list
      end
    end
  end

  def add_items
    if params[:add_all_items] == "true"
      documents = @item_list.getAllItemsFromSearch(params[:query_params])
    else
      documents = params[:document_ids].split(",")
    end

    addItemsResult = add_item_to_item_list(@item_list, documents)
    added_set = addItemsResult[:addedItems]

    session[:profiler] = addItemsResult[:profiler]

    flash[:notice] = "#{view_context.pluralize(added_set.size, "")} added to item list #{@item_list.name}"
    redirect_to @item_list
  end

  def clear
    bench_start = Time.now
    removed_set = @item_list.clear
    bench_end = Time.now

    Rails.logger.debug("Time for clear item list of #{removed_set.size} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    session[:profiler] = ["Time for clear item list of #{removed_set.size} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    flash[:notice] = "#{view_context.pluralize(removed_set.size, "")} cleared from item list #{@item_list.name}"
    redirect_to @item_list
  end

  def destroy
    bench_start = Time.now

    name = @item_list.name
    removed_set = @item_list.clear
    @item_list.delete

    bench_end = Time.now

    Rails.logger.debug("Time for deleting an Item list of #{removed_set.size} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    session[:profiler] = ["Time for deleting an Item list of #{removed_set.size} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    flash[:notice] = "Item list #{name} deleted successfully"
    redirect_to item_lists_path
  end

  def concordance_search
    result = @item_list.doConcordanceSearch(params[:concordance_search_for])

    if (result[:error].nil? or result[:error].empty?)
      @highlighting = result[:highlighting]
      @matchingDocs = result[:matching_docs]
      @profiler = result[:profiler]
      flash[:error] = nil
    else
      flash[:error] = result[:error]
    end

  end

  def frequency_search
    result = @item_list.doFrequencySearch(params[:frequency_search_for], params[:facet])
    if (result[:error].nil? or result[:error].empty?)
      flash[:error] = nil
      @result = result
    else
      flash[:error] = result[:error]
    end
  end

  def download_config_file
    if current_user.authentication_token.nil? #generate auth token if one doesn't already exist
      current_user.reset_authentication_token!
    end

    file = Tempfile.new("newfile")
    file.write(current_user.authentication_token)
    file.close
    send_file file.path, :filename => "hcsvlab.config", :disposition => "attachment"
  end

  #
  #
  #
  def download_as_zip
    begin
      bench_start = Time.now

      # Get the items of the item list
      itemsId = @item_list.get_item_ids

      # Creates a ZIP file containing the documents and item's metadata
      zip_path = get_zip_with_documents_and_metadata(itemsId)

      # Sends the zipped file
      file_name = "#{@item_list.name}.zip"
      send_data IO.read(zip_path), :type => 'application/zip',
                :disposition => 'attachment',
                :filename => file_name

      Rails.logger.debug("Time for downloading metadata and documents for #{itemsId.length} items: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

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

  private

  def add_item_to_item_list(item_list, documents_ids)
    item_list.add_items(documents_ids) unless item_list.nil?
  end

  #
  # Creates a ZIP file containing all the documents and metadata for the items listed in 'itemsId'.
  # The returned format respect the BagIt format (http://en.wikipedia.org/wiki/BagIt)
  #
  def get_zip_with_documents_and_metadata(itemsId)
    if (!itemsId.nil? and !itemsId.empty?)
      begin
        fileNamesByItem = get_documents_path(itemsId)

        digest_filename = Digest::MD5.hexdigest(itemsId.inspect.to_s)
        bagit_path = "#{Rails.root.join("tmp", "#{digest_filename}_tmp")}"
        Dir.mkdir bagit_path

        # make a new bag at base_path
        bag = BagIt::Bag.new bagit_path

        # add items metadata to the bag
        add_items_metadata_to_the_bag(fileNamesByItem, bag)

        # add items documents to the bag
        add_items_documents_to_the_bag(fileNamesByItem, bag)

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
        title = file.split('/').last
        # make a new file
        bag.add_file("#{handle}/#{title}") do |io|
          io.puts IO.read(file)
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
  def add_items_metadata_to_the_bag(fileNamesByItem, bag, batch_group = 50)
    itemsId = fileNamesByItem.keys
    itemsId.in_groups_of(batch_group, false) do |groupOfItemsId|
      # create disjunction condition with the items Ids
      condition = groupOfItemsId.map{|itemId| "id:\"#{itemId.gsub(":", "\:")}\""}.join(" OR ")

      params[:q] = condition
      params[:rows] = FIXNUM_MAX

      (response, document_list) = get_search_results params
      document_list.each do |aDoc|
        handle = aDoc['handle'].gsub(":", "_")
        itemId = aDoc['id']
        fileNamesByItem[itemId][:handle] = handle


        #json = get_item_metadata_in_json_format(aDoc)
        #itemMetadata = json.to_json

        @document = aDoc
        renderer = Rabl::Renderer.new('catalog/show', @document, { :format => 'json', :view_path => 'app/views', :scope => self })
        itemMetadata = renderer.render

        bag.add_file("#{handle}/#{handle}-metadata.json") do |io|
          io.puts itemMetadata
        end

        #puts "### Stat: " + GC.stat.inspect

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