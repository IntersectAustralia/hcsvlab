class ItemListsController < ApplicationController

  before_filter :authenticate_user!

  # Set itemList tab as current selected
  set_tab :itemList
  
  def index
    @userItemLists = ItemList.where(:user_id => current_user.id)

    @userItemLists = [] if @userItemLists.nil?

    #@response = ItemList.new.get_items
    #@document_list = @response["response"]["docs"]
  end

  def show
    itemList = ItemList.find_by_id!(params[:id])

    @response = itemList.get_items
    @document_list = @response["response"]["docs"]

    render index
  end
  
  def create
    @itemList = ItemList.new(:name => params[:item_list][:name].strip, :user_id => current_user.id)
    @documents = params[:document_ids].split(",")
    if @itemList.save
      flash[:notice] = 'Item list created successfully'

      add_item_to_item_list(@itemList, @documents)

      redirect_to itemList_path(@itemList)
    end
    
  end

  def add_to_item_list
    itemList = ItemList.find_by_id(params[:itemListId])
    documents = params[:document_ids].split(",")

    add_item_to_item_list(itemList, documents)
    redirect_to itemList_path(itemList)
  end

  def remove
    itemList = ItemList.find_by_id(params[:id])
    # Implement remove
    redirect_to itemLists_path
  end

  def clear
    itemList = ItemList.find_by_id(params[:id])
    # Implement clear
    redirect_to itemList_path(itemList)
  end

  private

  def add_item_to_item_list(itemList, documents_ids)
    if (!itemList.nil?)
      #TODO: call method to update solr items to link to this item list
    end
  end
  
end