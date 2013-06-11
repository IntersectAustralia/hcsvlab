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

  def clear
    itemList = ItemList.find_by_id!(params[:id])
    removed_set = itemList.clear
    flash[:notice] = "#{removed_set.size} Item#{removed_set.size==1? 's': ''} cleared from Item List #{itemList.name}"
    redirect_to itemList_path(itemList)
  end

  def destroy
    itemList = ItemList.find_by_id!(params[:id])
    name = itemList.name
    itemList.clear
    itemList.delete
    flash[:notice] = "Item list #{name} deleted"
    redirect_to itemLists_path
  end

  private

  def add_item_to_item_list(itemList, documents_ids)
    if (!itemList.nil?)
      #TODO: call method to update solr items to link to this item list
    end
  end

end