class ItemListsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :itemList

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
      if (!name.nil? and !name.blank?) and !params[:items].nil?
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
        err_message << " not found"
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

  private

  def add_item_to_item_list(item_list, documents_ids)
    item_list.add_items(documents_ids) unless item_list.nil?
  end

end