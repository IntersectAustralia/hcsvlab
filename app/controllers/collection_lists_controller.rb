class CollectionListsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :collectionList

  def index
    @userCollectionLists = CollectionList.find_by_owner_id(current_user.id)
  end

  def show
    @userCollectionLists = CollectionList.find_by_owner_id(current_user.id)

    begin
      @currentCollectionList = CollectionList.find(params[:id])
    rescue ActiveFedora::ObjectNotFoundError
      @currentCollectionList = nil
    end
    #respond_to do |format|
    #  format.json
    #  format.html { render :index }
    #end

  end

  def create
    if params[:add_all_collections] == 'true'
      collections = Collection.find_by_owner_email_and_unassigned(current_user.email).map{ |c| c.id}
    else
      collections = params[:collection_ids].split(",")
    end

    if (collections.length > 0)
      collectionList = CollectionList.new
      collectionList.name = params[:collection_list][:name]
      collectionList.ownerEmail = current_user.email
      collectionList.ownerId = current_user.id.to_s

      if collectionList.save
        add_collections_to_collection_list(collectionList, collections)
        flash[:notice] = 'Collections list created successfully'
        redirect_to licences_path
      end
    else
      flash[:error] = "You can not create an empty Collection List, please select at least one Collection."
      redirect_to licences_path
    end


  end

  def add_collections
    if params[:add_all_collections] == "true"
      collections = Collection.find_by_owner_email_and_unassigned(current_user.email).map{ |c| c.id}
    else
      collections = params[:collection_ids].split(",")
    end

    if (collections.length > 0)
      collectionList = CollectionList.find(params[:id])

      add_collections_to_collection_list(collectionList, collections)
      flash[:notice] = "#{view_context.pluralize(collections.size, "")} added to Collection list #{collectionList.flat_name}"
      redirect_to licences_path
    else
      flash[:error] = "You can not create an empty Collection List, please select at least one Collection."
      redirect_to licences_path
    end

  end

  def destroy
    bench_start = Time.now

    collectionList = CollectionList.find(params[:id])

    name = collectionList.flat_name
    collectionList.collections.each do |aCollection|
      aCollection.collectionList = nil
      aCollection.licence = nil
      aCollection.save!
    end

    collectionList.delete

    Rails.logger.debug("Time for deleting an Item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "Collection list #{name} deleted successfully"
    redirect_to licences_path
  end

  def add_licence_to_collection_list
    collectionList = CollectionList.find(params[:id])
    collectionList.add_licence(params[:licence_id])

    flash[:notice] = "Successfully added licence to #{collectionList.flat_name}"
    redirect_to licences_path
  end

  private

  def add_collections_to_collection_list(collection_list, collections_ids)
    collection_list.add_collections(collections_ids) unless collection_list.nil?
  end
end
