class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @collectionLists = CollectionList.find(ownerEmail: current_user.email)

    @collections = Collection.find(private_data_owner: current_user.email)
  end

  def show
  end

  def new
  end

end
