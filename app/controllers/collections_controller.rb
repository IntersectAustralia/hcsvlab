class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource

  set_tab :collection

  PER_PAGE_RESULTS = 20

  #
  #
  #
  def index
    @collections = getCollectionsIHaveAccess()
  end

  #
  #
  #
  def show
    @collections = getCollectionsIHaveAccess()

    begin
      @collection = Array(Collection.find_by_short_name(params[:id])).first
    rescue Exception => e
      #error handled below
    end
    respond_to do |format|
      if @collection.nil? or @collection.flat_short_name.nil?
        format.html { 
            flash[:error] = "Collection does not exist with the given id"
            redirect_to collections_path }
        format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
      else
        format.html { render :index }
        format.json {}
      end
    end
  end

  def new
  end

  #
  #
  #
  def add_licence_to_collection
    collection = Collection.find(params[:collection_id])
    licence = Licence.find (params[:licence_id])

    collection.setLicence(licence)

    flash[:notice] = "Successfully added licence to #{collection.flat_short_name}"
    redirect_to licences_path(:hide=>(params[:hide] == true.to_s)?"t":"f")
  end

  #
  #
  #
  def change_collection_privacy
    collection = Collection.find(params[:id])
    private = params[:privacy]
    collection.setPrivacy(private)
    if private=="false"
      UserLicenceRequest.where(:request_id => collection.id).destroy_all
    end
    private=="true" ? state="requiring approval" : state="not requiring approval"
    flash[:notice] = "#{collection.flat_name} has been successfully marked as #{state}"
    redirect_to licences_path
  end

  #
  #
  #
  def revoke_access
    collection = Collection.find(params[:id])
    UserLicenceRequest.where(:request_id => collection.id).destroy_all if collection.private?
    UserLicenceAgreement.where("group_name LIKE :prefix", prefix: "#{collection.flat_name}%").destroy_all
    flash[:notice] = "All access to #{collection.flat_name} has been successfully revoked"
    redirect_to licences_path
  end

  private

  #
  # Retrieve the collections I have access right
  #
  def getCollectionsIHaveAccess
    collection = Collection.all.select { |c| can? :discover, c }
    return collection.sort_by { |coll| coll.flat_short_name }
  end

  #
  # Creates the model for blacklight pagination.
  #
  #def create_pagination_structure(params)
  #  start = (params[:page].nil?)? 0 : params[:page].to_i-1
  #  total = @collections.length
  #
  #  per_page = (params[:per_page].nil?)? PER_PAGE_RESULTS : params[:per_page].to_i
  #  per_page = PER_PAGE_RESULTS if per_page < 1
  #
  #  current_page = (start / per_page).ceil + 1
  #  num_pages = (total / per_page.to_f).ceil
  #
  #  total_count = total
  #
  #  @collections = @collections[(current_page-1)*per_page..current_page*per_page-1]
  #
  #  start_num = start + 1
  #  end_num = start_num + @collections.length - 1
  #
  #  @paging = OpenStruct.new(:start => start_num,
  #                           :end => end_num,
  #                           :per_page => per_page,
  #                           :current_page => current_page,
  #                           :num_pages => num_pages,
  #                           :limit_value => per_page, # backwards compatibility
  #                           :total_count => total_count,
  #                           :first_page? => current_page > 1,
  #                           :last_page? => current_page < num_pages
  #  )
  #end

end
