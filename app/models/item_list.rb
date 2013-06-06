class ItemList < ActiveRecord::Base

  belongs_to :user

  attr_accessible :name, :id

  validates :name, presence: true

  #
  # Class variables for information about Solr
  #
  @@solr_config = nil
  @@solr = nil

  #
  # Initialise the connection to Solr
  #
  def get_solr_connection
    if @@solr_config.nil?
      @@solr_config = Blacklight.solr_config
      @@solr        = RSolr.connect(@@solr_config)
    end
  end

  def get_item_ids
    get_solr_connection

    # The query is: give me items which have my item_list.id in their item_lists field
    params = {:start=>0, :q=>"item_lists:#{RSolr.escape(id.to_s)}", :fl=>"id"}
    max_rows = 10

    # Loop around the query upping the :rows we ask for until we have them all
    begin
        max_rows = max_rows * 10
        params[:rows] = max_rows
        response = @@solr.get('select', params: params)
    end until response["response"]["numFound"] <= max_rows

    # Now extract the ids from the response
    return response["response"]["docs"].map { |thingy| thingy["id"] }
  end
  
end