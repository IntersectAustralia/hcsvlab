class LicencesController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource

  def index

  end

  def new
    @collections = Collection.all

  end

  def create
    name = params[:name]
    text = params[:text]
    #collection = eval(params[:collections])

    newLicence = Licence.new
    newLicence.save!

    newLicence.name = name
    newLicence.text = text
    newLicence.type = Licence::LICENSE_TYPE_PRIVATE
    newLicence.ownerId = current_user.id.to_s
    newLicence.ownerEmail = current_user.email
    newLicence.save!

    flash[:notice] = "Licence created successfully"
    redirect_to new_licence_path
  end
end