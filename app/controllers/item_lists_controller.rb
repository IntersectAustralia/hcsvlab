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
end