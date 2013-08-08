include ActionView::Helpers::SanitizeHelper

class LicencesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  PER_PAGE_RESULTS = 20

  def index
    @licences = Licence.where(type: Licence::LICENCE_TYPE_PUBLIC).to_a.concat(Licence.where(ownerId: current_user.id.to_s).to_a)
    @collection_lists = CollectionList.where(ownerId: current_user.id.to_s).to_a
    #
    # used to populate the drop downs
    @collectionLists = CollectionList.find(ownerEmail: current_user.email)

    @collections = Collection.find(private_data_owner: current_user.email)

    create_pagination_structure(params)

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
    text = params[:text].gsub('\'', '"')
    collectionListId = params[:collectionList]

    begin
      tags = %w(a acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p table td tr)
      sanitizedText = sanitize(text, tags: tags, attributes: %w(href title))

      # First we have to create the collection.
      newLicence = Licence.new
      newLicence.name = name
      newLicence.text = sanitizedText
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



  private

  def create_pagination_structure(params)
    start = (params[:page].nil?)? 0 : params[:page].to_i-1
    total = @collections.length

    per_page = (params[:per_page].nil?)? PER_PAGE_RESULTS : params[:per_page].to_i
    per_page = PER_PAGE_RESULTS if per_page < 1

    current_page = (start / per_page).ceil + 1
    num_pages = (total / per_page.to_f).ceil

    total_count = total

    @collections = @collections[(current_page-1)*per_page..current_page*per_page-1]

    start_num = start + 1
    end_num = start_num + @collections.length - 1

    @paging = OpenStruct.new(:start => start_num,
                             :end => end_num,
                             :per_page => per_page,
                             :current_page => current_page,
                             :num_pages => num_pages,
                             :limit_value => per_page, # backwards compatibility
                             :total_count => total_count,
                             :first_page? => current_page > 1,
                             :last_page? => current_page < num_pages
    )

  end

end
