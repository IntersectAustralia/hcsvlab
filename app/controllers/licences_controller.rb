class LicencesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
  end

  def show
  end

  def new

    #TODO: The List of collection list to which we are going to assing the new licence is going to come as a param in the request
    #TODO: Uncomment and adapt this lines.
    #@collectionLists = []
    #params[:collectionListIds].each do |aCollectionListId|
    #  @collectionLists << CollectionList.find(aCollectionListId)
    #end

    # TODO: By now I will get all the CollectionList instances
    @collectionLists = CollectionList.all

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
end
