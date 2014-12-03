class CollectionListsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :collectionList

  def index
    @userCollectionLists = current_user.collection_lists
  end

  def show
    @userCollectionLists = current_user.collection_lists

    begin
      @currentCollectionList = CollectionList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @currentCollectionList = nil
    end
  end

  def create
    if params[:add_all_collections] == 'true'
      collections = Collection.where(owner_id: current_user.id, collection_list_id: nil).pluck(:id)
    else
      collections = params[:collection_ids].split(",")
    end
    if collections.length > 0
      begin
        collection_list = current_user.collection_lists.new(params[:collection_list])
        add_collections_to_collection_list(collection_list, collections)
        flash[:notice] = 'Collections list created successfully'
      rescue ActiveRecord::RecordInvalid => e
        errors = ""
        e.record.errors.messages.each do |key, value|
          value.each do |value2|
            errors = errors + " #{value2}"
          end
        end

        flash[:error] = "Error creating a collection list. #{errors}"
      end
    else
      flash[:error] = "You can not create an empty Collection List, please select at least one Collection."
    end
    redirect_to licences_path(:hide => (params[:hide] == true.to_s) ? "t" : "f")
  end

  def add_collections
    if params[:add_all_collections] == "true"
      collections = current_user.collections.where(collection_list_id: nil).pluck(:id)
    else
      collections = params[:collection_ids].split(",")
    end

    if collections.length > 0
      collection_list = CollectionList.find(params[:id])

      add_collections_to_collection_list(collection_list, collections)
      flash[:notice] = "#{view_context.pluralize(collections.size, "")} added to Collection list #{collection_list.name}"
    else
      flash[:error] = "You can not create an empty Collection List, please select at least one Collection."
    end

    redirect_to licences_path(:hide => (params[:hide] == true.to_s) ? "t" : "f")
  end

  def remove_collection
    collectionListId = params[:collectionListId]
    collectionId = params[:collectionId]

    collectionList = CollectionList.find(collectionListId)
    colListSize = collectionList.collections.length
    colListName = collectionList.name
    collectionList.remove_collection(collectionId)

    if colListSize <= 1
      flash[:notice] = "The collection list '#{colListName}' was removed."
    else
      flash[:notice] = "The collection was removed from '#{collectionList.name}'."
    end

    redirect_to licences_path

  end

  def destroy
    bench_start = Time.now

    collectionList = CollectionList.find(params[:id])

    name = collectionList.name
    UserLicenceRequest.where(request_id: collectionList.id.to_s).delete_all
    collectionList.destroy

    Rails.logger.debug("Time for deleting an Item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "Collection list #{name} deleted successfully"
    redirect_to licences_path(:hide => (params[:hide] == true.to_s) ? "t" : "f")
  end

  def add_licence_to_collection_list
    collection_list = CollectionList.find(params[:id])
    collection_list.set_licence(params[:licence_id])

    flash[:notice] = "Successfully added licence to #{collection_list.name}"
    redirect_to licences_path(:hide => (params[:hide] == true.to_s) ? "t" : "f")

  end

  def change_collection_list_privacy
    collection_list = CollectionList.find(params[:id])
    private = params[:privacy]
    collection_list.set_privacy(private)
    if private=="false"
      UserLicenceRequest.where(:request_id => collection_list.id.to_s).destroy_all
    end
    private=="true" ? state="requiring approval" : state="not requiring approval"
    flash[:notice] = "#{collection_list.name} has been successfully marked as #{state}"
    redirect_to licences_path
  end

  def revoke_access
    coll_list = CollectionList.find(params[:id])
    UserLicenceRequest.where(:request_id => coll_list.id.to_s).destroy_all if coll_list.private?
    coll_list.collections.each do |collection|
      UserLicenceAgreement.where("group_name LIKE :prefix", prefix: "#{collection.name}%").destroy_all
    end
    flash[:notice] = "All access to #{coll_list.name} has been successfully revoked"
    redirect_to licences_path
  end

  private

  def add_collections_to_collection_list(collection_list, collections_ids)
    collection_list.add_collections(collections_ids) unless collection_list.nil?
  end
end
