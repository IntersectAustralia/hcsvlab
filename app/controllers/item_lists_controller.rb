require "#{Rails.root}/lib/item/download_items_helper.rb"

class ItemListsController < ApplicationController
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::CatalogHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include Item::DownloadItemsHelper

  before_filter :authenticate_user!
  before_filter :validate_id_parameter
  load_and_authorize_resource

  # This method will inject currentUser and currentAbility to the instance of ItemList
  # Those values are required by Hydra Access Control.
  before_filter :inject_user_and_ability_to_item_list
  before_filter :retrieve_item_lists, only: [:index, :show, :concordance_search, :frequency_search]

  FIXNUM_MAX = 2147483647

  # Set itemList tab as current selected
  set_tab :itemList

  #
  #
  #
  def index
    if session[:profiler]
      @profiler = session[:profiler]
      session.delete(:profiler)
    end
  end

  #
  #
  #
  def show
    if session[:profiler]
      @profiler = session[:profiler]
      session.delete(:profiler)
    end

    params[:per_page] = params[:per_page].to_i if params[:per_page].is_a? String
    respond_to do |format|
      format.html {
        @response = @item_list.get_items(params[:page], params[:per_page])
        @document_list = @response["response"]["docs"]

        authorised_item_handles = @item_list.get_authorised_item_handles
        if @response['response']['numFound'] > authorised_item_handles.size
          all_collections = @item_list.get_item_handles.collect { |item| item.split(":")[0]}.uniq
          collections_with_permission = authorised_item_handles.collect { |item| item.split(":")[0]}.uniq
          @missing_collections = (all_collections - collections_with_permission).join(", ")
          @message = "You only have access to #{authorised_item_handles.size} out of #{@response['response']['numFound']} Items in this shared Item List."
        end

        if current_user.authentication_token.nil? #generate auth token if one doesn't already exist
          current_user.reset_authentication_token!
        end

        render :index
      }
      format.json {
        @response = @item_list.get_items(params[:page], params[:per_page])
        @document_list = @response["response"]["docs"]
      }
      format.zip {
        if @item_list.get_item_handles.length == 0
          flash[:error] = "No items in the item list you are trying to download"
          redirect_to @item_list and return
        end

        download_as_zip(@item_list.get_item_handles, "#{@item_list.name}.zip")
      }
      format.warc {
        if @item_list.get_item_handles.length == 0
          flash[:error] = "No items in the item list you are trying to download"
          redirect_to @item_list and return
        end

        download_as_warc(@item_list.get_item_handles, "#{@item_list.name}.warc")
      }
    end
  end

  #
  #
  #
  def create
    if request.format == 'json' and request.post?
      name = params[:name]
      if (!name.nil? and !name.blank? and !(name.length > 255)) and (!params[:items].nil? and params[:items].is_a? Array)
        @item_list = current_user.item_lists.find_or_initialize_by_name(name)
        inject_user_and_ability_to_item_list
        is_new_item_list = @item_list.new_record?
        @item_list.save!
        ids = params[:items].collect { |x| "#{File.basename(File.split(x).first)}:#{File.basename(x)}" }
        add_items_result = add_item_to_item_list(@item_list, ids)
        added_set = add_items_result[:addedItems]
        if is_new_item_list
          @success_message = "#{added_set.count} items added to new item list #{@item_list.name}"
        else
          @success_message = "#{added_set.count} items added to existing item list #{@item_list.name}"
        end
      else
        err_message = "name parameter" if name.nil? or name.blank? or name.length > 255
        err_message = "items parameter" if params[:items].nil?
        err_message = "name and items parameters" if (name.nil? or name.blank?) and params[:items].nil?
        err_message << " not found" if !err_message.nil?
        err_message = "items parameter not an array" if !params[:items].is_a? Array and err_message.nil?
        respond_to do |format|
          format.any { render :json => {:error => err_message}.to_json, :status => 400 }
        end
      end
    else
      name = params[:item_list][:name]
      item_list = current_user.item_lists.find_by_name(name)
      inject_user_and_ability_to_item_list
      if item_list.nil?
        if params[:all_items] == 'true'
          documents = @item_list.get_all_items_from_search(params[:query_all_params])
          documents = documents.map { |d| d['handle'] }
        else
          documents = params[:sel_document_ids].split(",")
        end
        if documents.empty?
          flash[:error] = "No items were selected to add to item list"
          redirect_to :back and return
        end
        if @item_list.save
          flash[:notice] = 'Item list created successfully'

          add_items_results = add_item_to_item_list(@item_list, documents)
          session[:profiler] = add_items_results[:profiler]
          redirect_to @item_list and return
        end
        flash[:error] = "Error trying to create an Item list, name too long (max. 255 characters)" if (name.length > 255)
        flash[:error] = "Error trying to create an Item list" unless (name.length > 255)
        redirect_to :back and return
      else
        flash[:error] = "Item list with name '#{name}' already exists."
        redirect_to :back and return
      end
    end
  end

  #
  #
  #
  def add_items
    if params[:add_all_items] == "true"
      documents = @item_list.get_all_items_from_search(params[:query_params])
      documents = documents.map { |d| d['handle'] }
    else
      documents = params[:document_ids].split(",")
    end

    if documents.empty?
      flash[:error] = "No items were selected to add to item list"
      redirect_to :back and return
    end

    addItemsResult = add_item_to_item_list(@item_list, documents)
    added_set = addItemsResult[:addedItems]

    session[:profiler] = addItemsResult[:profiler]

    flash[:notice] = "#{view_context.pluralize(added_set.size, "")} added to item list #{@item_list.name}"
    redirect_to @item_list
  end

  #
  # This method with update and rename the item list
  #
  def update
    if request.format == 'json' and request.put?
      @item_list = ItemList.find(params[:id])
      name = params[:name]
      item_lists = current_user.item_lists.find_by_name(name)

      if (!name.nil? and !name.blank? and !(name.length > 255)) and (item_lists.nil? or @item_list.name == name)
        @item_list.name = name
        if @item_list.save
          render "show" and return
        end
      end

      err_message = "couldn't rename item list"
      err_message = "name too long" if !name.nil? and name.length > 255
      err_message = "name can't be blank" if name.blank?

      respond_to do |format|
        format.any { render :json => {:error => err_message}.to_json, :status => 400 }
      end

    else
      name = params[:item_list][:name]
      item_lists = current_user.item_lists.find_by_name(name)
      if item_lists.nil? or @item_list.name.eql?(name)
        if @item_list.update_attributes(params[:item_list])
          flash[:notice] = 'Item list renamed successfully'
          redirect_to @item_list and return
        end
        flash[:error] = "Error trying to rename Item list, name too long (max. 255 characters)" if (name.length > 255)
        flash[:error] = "Error trying to rename Item list, name can't be blank" if (name.blank?)
        flash[:error] = "Error trying to rename Item list" unless (name.length > 255) or (name.blank?)
        redirect_to @item_list and return
      else
        flash[:error] = "Item list with name '#{name}' already exists."
        redirect_to @item_list and return
      end
    end
  end

  #
  # This method with remove all the items in an item list but it will not remove the item list
  #
  def clear
    bench_start = Time.now
    removed_set = @item_list.clear
    bench_end = Time.now

    Rails.logger.debug("Time for clear item list of #{removed_set} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    session[:profiler] = ["Time for clear item list of #{removed_set} items: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    message = "#{view_context.pluralize(removed_set, "")}cleared from item list #{@item_list.name}"
    respond_to do |format|
      format.html do
        flash[:notice] = message
        redirect_to @item_list
      end

      format.json { render :json => {:success => message} }
    end
  end

  #
  # This method with remove an item list from the system
  #
  def destroy
    bench_start = Time.now

    name = @item_list.name
    @item_list.destroy

    bench_end = Time.now

    Rails.logger.debug("Time for deleting an Item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    session[:profiler] = ["Time for deleting an Item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    respond_to do |format|
      format.html do
        flash[:notice] = "Item list #{name} deleted successfully"
        redirect_to item_lists_path
      end

      format.json { render :json => {:success => "item list #{@item_list.name} deleted successfully"} }
    end
  end

  #
  # This method with set an item list a shared
  #
  def share
    @item_list.share
    message = "Item list #{@item_list.name} is shared. Any user in the application will be able to see it."

    respond_to do |format|
      format.html do
        flash[:notice] = message
        redirect_to @item_list
      end

      format.json { render :json => {:success => message} }
    end

  end

  #
  # This method with set an item list a not shared
  #
  def unshare
    @item_list.unshare
    message = "Item list #{@item_list.name} is not being shared anymore."

    respond_to do |format|
      format.html do
        flash[:notice] = message
        redirect_to @item_list
      end

      format.json { render :json => {:success => message} }
    end

  end

  #
  #
  #
  def concordance_search
    result = @item_list.doConcordanceSearch(params[:concordance_search_for])

    if result[:error].nil? or result[:error].empty?
      @highlighting = result[:highlighting]
      @matchingDocs = result[:matching_docs]
      @profiler = result[:profiler]
      flash[:error] = nil
    else
      flash[:error] = result[:error]
    end

  end

  #
  #
  #
  def frequency_search
    result = @item_list.doFrequencySearch(params[:frequency_search_for], params[:facet])
    if result[:error].nil? or result[:error].empty?
      flash[:error] = nil
      @result = result
    else
      flash[:error] = result[:error]
    end
  end

  private

  #
  #
  #
  def add_item_to_item_list(item_list, item_handles)
    item_list.add_items(item_handles) unless item_list.nil?
  end

  #
  #
  #
  def validate_id_parameter
    if params[:id].to_i > FIXNUM_MAX
      resource_not_found(Exception.new("Couldn't find ItemList with id=#{params[:id]}"))
    end
  end

  #
  # This method will inject currentUser and currentAbility to the instance of ItemList
  # Those values are required by Hydra Access Control.
  #
  def inject_user_and_ability_to_item_list
    if @item_list
      @item_list.set_current_user(current_user)
      @item_list.set_current_ability(current_ability)
    end
  end

  #
  # This method will set the current user owned item list and also the shared ones
  #
  def retrieve_item_lists
    @user_item_lists = current_user.item_lists.order("lower(name)")
    @shared_item_lists = ItemList.order("lower(name)").where('shared = ? AND user_id != ?', true, current_user.id)
  end
end
