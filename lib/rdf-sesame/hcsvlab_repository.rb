require 'linkeddata'
require 'rdf/sesame'
require 'active_support/core_ext/array/grouping'

module RDF::Sesame
  ##
  # A repository on a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent RDF repositories on Sesame-compatible
  # servers.
  #
  # @example Opening a Sesame repository (1)
  #   url = "http://localhost:8080/openrdf-sesame/repositories/SYSTEM"
  #   repository = RDF::Sesame::HcsvlabRepository.new(url)
  #
  # @example Opening a Sesame repository (2)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   repository = RDF::Sesame::HcsvlabRepository.new(:server => server, :id => :SYSTEM)
  #
  # @example Opening a Sesame repository (3)
  #   server = RDF::Sesame::Server.new("http://localhost:8080/openrdf-sesame")
  #   repository = server.repository(:SYSTEM)
  #
  # @see RDF::Sesame
  # @see http://www.openrdf.org/doc/sesame2/system/ch08.html
  class HcsvlabRepository < RDF::Sesame::Repository

    #
    # Inserts the statements given in the RDF file path into this repository.
    #
    # @param  [string] rdf_glob
    # @param  [RDF::URI] context (Optional)
    # @param  [integer] group_size
    #
    def insert_from_rdf_files(rdf_glob, context = nil, group_size = 100)
      total = 0
      count = 0
      data = ""
      Dir.glob(rdf_glob) do |file|
        data += IO.read(file)
        if count == group_size
          send_statements(context, data)
          total += count
          count = 0
          data = ""
        else
          count += 1
        end
      end
      if data.present?
        send_statements(context, data)
        total += count
      end
      total
    end

    def send_statements(context, data)
      statements_options = {}
      statements_options[:context] = "<#{context.to_s}>" if !context.nil?

      response = server.post(self.path(:statements, statements_options), data, 'Content-Type' => 'application/x-turtle;charset=UTF-8')
      raise Exception.new(response.message) unless "204".eql?(response.code)
    end

  end # class Repository
end # module HCSVLAB::RDF::Sesame