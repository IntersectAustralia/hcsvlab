class AdminController < ActionController::Base
  before_filter :authenticate_user!
  #load_and_authorize_resource

  def index

  end

  def newLicenceForm
    @collections = Collection.all

  end

  def createNewLicense
    name = params[:name]
    text = params[:text]
    collection = eval(params[:collections])

    newLicence = License.new
    #newLicence.save!

    newLicence.name = name
    newLicence.text = text
    newLicence.type = License::LicenceType::PRIVATE
    newLicence.owner = current_user.id
    #newLicence.save!

    flash[:notice] = "file uploaded"
    render :index
  end
end