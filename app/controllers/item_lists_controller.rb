class ItemListsController < ApplicationController

  before_filter :authenticate_user!
  #load_and_authorize_resource

  def index
    @userItemLists = ItemList.where(:user_id => current_user.id)

    @userItemLists = [] if @userItemLists.nil?
  end
end