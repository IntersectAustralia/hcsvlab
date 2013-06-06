class ItemListsController < ApplicationController

  before_filter :authenticate_user!

  # Set itemList tab as current selected
  set_tab :itemList

  def index
    @userItemLists = ItemList.where(:user_id => current_user.id)

    @userItemLists = [] if @userItemLists.nil?
  end
end