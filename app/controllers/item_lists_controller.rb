class ItemListsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :itemList

  def index
  end

  def show
    @response = @item_list.get_items(params[:page], params[:per_page])
    @document_list = @response["response"]["docs"]
    respond_to do |format|
      format.json
      format.html { render :index }
    end
    
  end
  
  def create
    if params[:all_items] == 'true'
      documents = @item_list.getAllItemsFromSearch(params[:query_all_params])
    else
      documents = params[:sel_document_ids].split(",")
    end
    if @item_list.save
      flash[:notice] = 'Item list created successfully'
      add_item_to_item_list(@item_list, documents)
      redirect_to @item_list
    end
  end

  def add_items
    if params[:add_all_items] == "true"
      documents = @item_list.getAllItemsFromSearch(params[:query_params])
    else
      documents = params[:document_ids].split(",")
    end

    added_set = add_item_to_item_list(@item_list, documents)
    flash[:notice] = "#{view_context.pluralize(added_set.size, "")} added to item list #{@item_list.name}"
    redirect_to @item_list
  end

  def clear
    bench_start = Time.now

    removed_set = @item_list.clear

    Rails.logger.debug("Time for clear item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "#{view_context.pluralize(removed_set.size, "")} cleared from item list #{@item_list.name}"
    redirect_to @item_list
  end

  def destroy
    bench_start = Time.now

    name = @item_list.name
    @item_list.clear
    @item_list.delete

    Rails.logger.debug("Time for deleting an Item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "Item list #{name} deleted successfully"
    redirect_to item_lists_path
  end

  def concordance_search
    result = @item_list.doConcordanceSearch(params[:search_for])

    if (result[:error].nil? or result[:error].empty?)
      @highlighting = result[:highlighting]
      @matchingDocs = result[:matching_docs]
      flash[:error] = nil
    else
      flash[:error] = result[:error]
    end
  end

  def frequency_search
    @result = @item_list.doFrequencySearch(params[:search_for], params[:facet])
  end

  private

  def add_item_to_item_list(item_list, documents_ids)
    item_list.add_items(documents_ids) unless item_list.nil?
  end

end