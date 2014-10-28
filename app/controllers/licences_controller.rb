include ActionView::Helpers::SanitizeHelper

class LicencesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  PER_PAGE_RESULTS = 50

  def index


    bench_start = Time.now

    # gets PUBLIC licences and the user licences.
    t = Licence.arel_table

    @licences = Licence.where(t[:private].eq(false).or(t[:owner_id].eq(current_user.id)))

    # gets the Collections list of the logged user.
    @collection_lists = current_user.collection_lists.includes(:owner, :licence).order(:name)

    # gets the Collections of the logged user.
    @collections = current_user.collections.order(:name)
    bench_end = Time.now
    @profiler = ["Time for fetching all collections, licences and collection lists took: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    create_pagination_structure(params)

  end

  def show
  end

  def new
    if params[:collectionList].present?
      @CollectionList = CollectionList.find(params[:collectionList])
      @Collection = nil
    elsif params[:collection].present?
      @Collection = Collection.find(params[:collection])
      @CollectionList = nil
    else
      @CollectionList = nil
      @Collection = nil
    end
  end

  def create
    name = params[:name]
    text = params[:text].gsub('\'', '"')
    collectionListId = params[:collectionList]
    collectionId = params[:collection]

    begin
      tags = %w(a acronym b strong i em span li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p table td tr)
      sanitizedText = sanitize(text, tags: tags, attributes: %w(href title style))

      # First we have to create the collection.
      newLicence = Licence.new
      newLicence.name = name
      newLicence.text = sanitizedText
      newLicence.private = true
      newLicence.owner_id = current_user.id.to_s
      newLicence.save!

      # Now lets assign the licence to every collection list
      if !collectionListId.nil?
        aCollectionList = CollectionList.find(collectionListId)
        aCollectionList.set_licence(newLicence.id)
      elsif !collectionId.nil?
        aCollection = Collection.find(collectionId)
        aCollection.setLicence(newLicence)
      end

      flash[:notice] = "Licence created successfully"

      #TODO: This should redirect to
      redirect_to licences_path
    rescue ActiveRecord::RecordInvalid => e
      @params = params
      if !collectionListId.nil?
        @CollectionList = CollectionList.find(collectionListId)
      end
      if !collectionId.nil?
        @Collection = Collection.find(collectionId)
      end
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
