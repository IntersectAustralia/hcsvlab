class ItemList < ActiveRecord::Base
  belongs_to :user

  attr_accessible :name, :id, :user_id

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
    max_rows = 100

    # First stab at the query
    params[:rows] = max_rows
    response = @@solr.get('select', params: params)

    # If there are more rows in Solr than we asked for, increase the number we're
    # asking for and ask for them all this time. Sadly, there doesn't appear to be
    # a "give me everything" value for the rows parameter.
    if response["response"]["numFound"] < max_rows
        params[:rows] = response["response"]["numFound"]
        response = @@solr.get('select', params: params)
    end

    # Now extract the ids from the response
    return response["response"]["docs"].map { |thingy| thingy["id"] }
  end

  def get_items(start = 0, rows = 20)
    get_solr_connection

    params = {:start=>start, :rows => rows, :q=>"item_lists:#{RSolr.escape(id.to_s)}"}

    solrResponse = @@solr.get('select', params: params)
    response = Blacklight::SolrResponse.new(force_to_utf8(solrResponse), params)

    return response
  end

  private

  def force_to_utf8(value)
    case value
      when Hash
        value.each { |k, v| value[k] = force_to_utf8(v) }
      when Array
        value.each { |v| force_to_utf8(v) }
      when String
        value.force_encoding("utf-8")  if value.respond_to?(:force_encoding)
    end
    value
  end

end