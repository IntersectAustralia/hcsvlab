class LicencesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @licences = Licence.where(type: Licence::LICENCE_TYPE_PUBLIC).to_a.concat(Licence.where(ownerId: current_user.id.to_s).to_a)
    @collection_lists = CollectionList.where(ownerId: current_user.id.to_s).to_a
  end

  def show
  end

  def new
    if params[:collection].present?
      @CollectionList = CollectionList.find(params[:collection])
    else
      @CollectionList = nil
    end
  end

  def create
    name = params[:name]
    text = params[:text]
    collectionListIds = eval(params[:collectionLists])

    # First we have to create the collection.
    newLicence = Licence.new
    newLicence.save!

    newLicence.name = name
    newLicence.text = text
    newLicence.type = Licence::LICENSE_TYPE_PRIVATE
    newLicence.ownerId = current_user.id.to_s
    newLicence.ownerEmail = current_user.email
    newLicence.save!

    # Now lets assign the licence to every collection list
    collectionListIds.each do |aCollectionListId|
      aCollectionList = CollectionList.find(aCollectionListId)
      aCollectionList.licence = newLicence
      aCollectionList.save!
    end

    flash[:notice] = "Licence created successfully"

    #TODO: This should redirect to
    redirect_to licence_path
  end

  def add_licence_to_collection
    collection = CollectionList.find(params[:collection_id])
    collection.add_licence(params[:licence_id])

    flash[:notice] = "Successfully added licence to #{collection.name.first}"
    redirect_to licences_path
  end

end
