require "#{Rails.root}/lib/rdf-sesame/hcsvlab_repository.rb"

module RDF::Sesame
  ##
  # A server endpoint compatible with the Sesame 2.0 HTTP protocol.
  #
  # Instances of this class represent Sesame-compatible servers that contain
  # one or more readable and/or writable RDF {Repository repositories}.
  #
  # @example Connecting to a Sesame server
  #   url    = RDF::URI.new("http://localhost:8080/openrdf-sesame")
  #   server = RDF::Sesame::Server.new(url)
  #
  # @example Retrieving the server's protocol version
  #   server.protocol                 #=> 4
  #
  # @example Iterating over available RDF repositories
  #   server.each_repository do |repository|
  #     puts repository.inspect
  #   end
  #
  # @example Finding all readable, non-empty RDF repositories
  #   server.find_all do |repository|
  #     repository.readable? && !repository.empty?
  #   end
  #
  # @example Checking if any RDF repositories are writable
  #   server.any? { |repository| repository.writable? }
  #
  # @example Checking if a specific RDF repository exists on the server
  #   server.has_repository?(:SYSTEM) #=> true
  #   server.has_repository?(:foobar) #=> false
  #
  # @example Obtaining a specific RDF repository
  #   server.repository(:SYSTEM)      #=> RDF::Sesame::Repository(SYSTEM)
  #   server[:SYSTEM]                 #=> RDF::Sesame::Repository(SYSTEM)
  #
  # @see RDF::Sesame
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class HcsvlabServer < RDF::Sesame::Server

    ACCEPT_JSON = {'Accept' => 'application/sparql-results+json'}.freeze
    ACCEPT_NTRIPLES = {'Accept' => 'text/plain'}.freeze

    RESULT_BOOL = 'text/boolean'.freeze
    RESULT_JSON = 'application/sparql-results+json'.freeze
    RESULT_XML = 'application/sparql-results+xml'.freeze

    # Native store
    NATIVE_STORE_TYPE = "native"
    # Native store with RDF Schema inferencing
    NATIVE_RDFS_STORE_TYPE = "native-rdfs"
    # Native store with RDF Schema and direct type inferencing
    NATIVE_RDFS_DT_STORE_TYPE = "native-rdfs-dt"


    #
    # Creates a new repository into this server.
    #
    # @param  [String] type
    # @param  [String] id
    # @param  [String] title
    # @param  [String] triple_indexes
    #
    def create_repository(type, id, title, triple_indexes='spoc,posc')
      data = IO.read("#{File.dirname(__FILE__)}/templates/#{type}.ttl")
      data.gsub!('___REPOSITORY_ID___', id)
      data.gsub!('___REPOSITORY_NAME___', title)
      data.gsub!('___REPOSITORY_INDEXES___', triple_indexes)


      system_repository = self.repository(:SYSTEM)
      if (!self.has_repository?(id))
        response = self.post(system_repository.path(:statements), data, 'Content-Type' => 'application/x-trig;charset=UTF-8')
        "204".eql?(response.code)
      else
        return false
      end
    end

    ##
    # Returns all repositories on this Sesame server.
    #
    # @return [Hash{String => Repository}]
    # @see    #repository
    # @see    #each_repository
    # @see    http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e204
    def repositories
      repositories = super
      repos = {}
      repositories.each_pair do |id, repo|

        # We need to buid a new instance in order to be able to use our methods.
        castedRepo = HcsvlabRepository.new({
                                               :server   => self,
                                               :uri      => repo.uri,
                                               :id       => repo.id,
                                               :title    => repo.title,
                                               :readable => repo.readable?,
                                               :writable => repo.writable?,
                                           })

        repos[id] = castedRepo
      end
      repos
    end


  end
end
