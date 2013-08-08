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
    collectionListId = params[:collectionList]

    begin
      # First we have to create the collection.
      newLicence = Licence.new
      newLicence.name = name
      newLicence.text = text
      newLicence.type = Licence::LICENCE_TYPE_PRIVATE
      newLicence.ownerId = current_user.id.to_s
      newLicence.ownerEmail = current_user.email
      newLicence.save!

      # Now lets assign the licence to every collection list
      if (!collectionListId.nil?)
        aCollectionList = CollectionList.find(collectionListId)
        aCollectionList.licence = newLicence
        aCollectionList.save!
      end

      flash[:notice] = "Licence created successfully"

      #TODO: This should redirect to
      redirect_to licences_path
    rescue ActiveFedora::RecordInvalid => e
      @params = params
      @errors = e.record.errors.messages
      render 'licences/new'
    end
  end

end
