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
    # @param  [Array] rdfFiles
    # @param  [integer] group_size
    #
    def insert_from_rdf_files(rdfFiles, group_size = 100)
      rdfFiles.in_groups_of(group_size).each do |fileUriGroup|

        data = ""
        fileUriGroup.each do |rdfFileUri|
          break if rdfFileUri.nil?
          data += IO.read(rdfFileUri)
        end

        response = server.post(self.url(:statements), data, 'Content-Type' => 'application/x-turtle')
        raise Exception.new(response.message) unless "204".eql?(response.code)
      end
    end
  end # class Repository
end # module HCSVLAB::RDF::Sesame