class ItemListsController < ApplicationController

  before_filter :authenticate_user!

  # Set itemList tab as current selected
  set_tab :itemList
  
  def index
    @userItemLists = ItemList.where(:user_id => current_user.id)

    @userItemLists = [] if @userItemLists.nil?

    @response = ItemList.new.get_items
    @document_list = @response["response"]["docs"]
  end
  
  def create
    @itemList = ItemList.new(:name => params[:item_list][:name].strip, :user_id => current_user.id)
    @documents = params[:document_ids].split(",")
    if @itemList.save
      flash[:notice] = 'Item list created successfully'
      #TODO: call method to update solr items to link to this item list
      redirect_to root_url
    end
    
  end
  
end