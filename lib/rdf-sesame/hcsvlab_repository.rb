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

    ##
    # Returns the server-relative path for the given repository-relative `path`.
    #
    # @param  [String, #to_s]        path
    # @param  [Hash, RDF::Statement] query
    # @return [String]
    def path(path = nil, query = {})
      url =  RDF::URI.new(path ? "repositories/#{@id}/#{path}" : "repositories/#{@id}")
      unless query.nil?
        case query
          when RDF::Statement
            writer = RDF::NTriples::Writer.new
            q  = {
                :subj    => writer.format_value(query.subject),
                :pred    => writer.format_value(query.predicate),
                :obj     => writer.format_value(query.object)
            }
            q.merge!(:context => writer.format_value(query.context)) if query.has_context?
            url.query_values = q
          when Hash
            url.query_values = query unless query.empty?
        end
      end
      return url.to_s
    end
    alias_method :uri, :url

    ##
    # A mapping of blank node results for this client
    # @private
    def nodes
      @nodes ||= {}
    end

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

        response = server.post(self.url(:statements, {}), data, 'Content-Type' => 'application/x-turtle')
        raise Exception.new(response.message) unless "204".eql?(response.code)
      end
    end


    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statement(statement)
      insert_statements([statement])
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    # @see http://www.openrdf.org/doc/sesame2/system/ch08.html#d0e304
    def insert_statements(statements)
      data = statements_to_text_plain(statements)

      response = server.post(self.url(:statements, statements_options), data, 'Content-Type' => 'text/plain')

      logger.debug("[#{DateTime.now}], [#{self.class.to_s}], [debug] #{response.inspect}") unless response.code == "204"

      response.code == "204"
    end

    # Run a raw SPARQL query.
    #
    # @overload sparql_query(query) {|solution| ... }
    #   @yield solution
    #   @yieldparam [RDF::Query::Solution] solution
    #   @yieldreturn [void]
    #   @return [void]
    #
    # @overload sparql_query(pattern)
    #   @return [Enumerator<RDF::Query::Solution>]
    #
    # @param [String] query The query to run.
    # @param [Hash{Symbol => Object}] options
    #   The query options (see build_query).
    # @return [void]
    #
    # @see #build_query
    def sparql_query(query, options={}, &block)
      raw_query(query, 'sparql', options, &block)
    end

    #def sparql_federated_query(query, options={}, &block)
    #  repositories_location = []
    #  server.repositories.each_pair do |repoId, repo|
    #    repositories_location << repo.url.to_s
    #  end
    #
    #  raw_query(query, 'sparql', options, &block)
    #end

    ##
    # Returns all statements of the given query.
    #
    # @private
    # @param  [String, #to_s]        query
    # @param  [String, #to_s]        queryLn
    # @return [RDF::Enumerator]
    def raw_query(query, queryLn = 'sparql', options={}, &block)
      options = { infer: true }.merge(options)

      response = if query =~ /\b(delete|insert)\b/i
                   write_query(query, queryLn, options)
                 else
                   read_query(query, queryLn, options)
                 end
    end

    #
    #
    #
    def read_query(query, queryLn, options)
      if queryLn == 'sparql' and options[:format].nil? and query =~ /\bconstruct\b/i
        options[:format] = HcsvlabServer::ACCEPT_NTRIPLES
      end

      options[:format] = HcsvlabServer::ACCEPT_JSON unless options[:format]

      params = Addressable::URI.form_encode({ :query => query, :queryLn => queryLn, :infer => options[:infer] }).gsub("+", "%20").to_s
      #url = Addressable::URI.parse(path)
      #unless url.normalize.query.nil?
      #  url.query = [url.query, params].compact.join('&')
      #else
      #  url.query = [url.query, params].compact.join('?')
      #end
      #response = server.post(url, options[:format])
      response = server.post(self.url, params, options[:format].merge({'Content-Type' => 'application/x-www-form-urlencoded'}))

      results = parse_response(response)
      if block_given?
        results.each {|s| yield s }
      else
        results
      end
    end

    #
    #
    #
    def write_query(query, queryLn, options)
      parameters = {}
      parameters[:update] = query
      response = server.post(path(:statements), Addressable::URI.form_encode(parameters), 'Content-Type' => 'application/x-www-form-urlencoded')
      response.code == "204"
    end


    private

    # Convert a list of statements to a text-plain-compatible text.
    def statements_to_text_plain(statements)
      graph = RDF::Repository.new
      statements.each do |s|
        graph << s
      end
      RDF::NTriples::Writer.dump(graph, nil, :encoding => Encoding::ASCII)
    end

    ##
    # @param [Net::HTTPSuccess] response
    # @param [Hash{Symbol => Object}] options
    # @return [Object]
    def parse_response(response, options = {})
      case content_type = options[:content_type] || response.content_type
        when HcsvlabServer::RESULT_BOOL
          response.body == 'true'
        when HcsvlabServer::RESULT_JSON
          self.class.parse_json_bindings(response.body, nodes)
        when HcsvlabServer::RESULT_XML
          self.class.parse_xml_bindings(response.body, nodes)
        else
          parse_rdf_serialization(response, options)
      end
    end

    ##
    # @param [String, Hash] json
    # @return [<RDF::Query::Solutions>]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_json_bindings(json, nodes = {})
      require 'json' unless defined?(::JSON)
      json = JSON.parse(json.to_s) unless json.is_a?(Hash)

      case
        when json['boolean']
          json['boolean']
        when json['results']
          solutions = RDF::Query::Solutions.new
          json['results']['bindings'].each do |row|
            row = row.inject({}) do |cols, (name, value)|
              cols.merge(name.to_sym => parse_json_value(value))
            end
            solutions << RDF::Query::Solution.new(row)
          end
          solutions
      end
    end

    ##
    # @param [Hash{String => String}] value
    # @return [RDF::Value]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_json_value(value, nodes = {})
      case value['type'].to_sym
        when :bnode
          nodes[id = value['value']] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value['value'])
        when :literal
          RDF::Literal.new(value['value'], :language => value['xml:lang'])
        when :'typed-literal'
          RDF::Literal.new(value['value'], :datatype => value['datatype'])
        else nil
      end
    end

    ##
    # @param [String, REXML::Element] xml
    # @return [<RDF::Query::Solutions>]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def self.parse_xml_bindings(xml, nodes = {})
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to?(:force_encoding)
      require 'rexml/document' unless defined?(::REXML::Document)
      xml = REXML::Document.new(xml).root unless xml.is_a?(REXML::Element)

      case
        when boolean = xml.elements['boolean']
          boolean.text == 'true'
        when results = xml.elements['results']
          solutions = RDF::Query::Solutions()
          results.elements.each do |result|
            row = {}
            result.elements.each do |binding|
              name = binding.attributes['name'].to_sym
              value = binding.select { |node| node.kind_of?(::REXML::Element) }.first
              row[name] = parse_xml_value(value, nodes)
            end
            solutions << RDF::Query::Solution.new(row)
          end
          solutions
      end
    end

    ##
    # @param [REXML::Element] value
    # @return [RDF::Value]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#variable-binding-results
    def self.parse_xml_value(value, nodes = {})
      case value.name.to_sym
        when :bnode
          nodes[id = value.text] ||= RDF::Node.new(id)
        when :uri
          RDF::URI.new(value.text)
        when :literal
          RDF::Literal.new(value.text, {
              :language => value.attributes['xml:lang'],
              :datatype => value.attributes['datatype'],
          })
        else nil
      end
    end

    ##
    # @param [Net::HTTPSuccess] response
    # @param [Hash{Symbol => Object}] options
    # @return [RDF::Enumerable]
    def parse_rdf_serialization(response, options = {})
      options = {:content_type => response.content_type} if options.empty?
      if reader_for = RDF::Reader.for(options)
        reader_for.new(response.body) do |reader|
          reader # FIXME
        end
      end
    end

    # @private
    #
    # Construct the statements options list
    def statements_options
      options = {}
      options[:context] = @context if @context
      options
    end

  end # class Repository
end # module HCSVLAB::RDF::Sesame