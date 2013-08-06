class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  PER_PAGE_RESULTS = 20

  def index
    # used to populate the drop downs
    @collectionLists = CollectionList.find(ownerEmail: current_user.email)

    @collections = Collection.find(private_data_owner: current_user.email)

    create_pagination_structure(params)
  end

  def show
  end

  def new
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
