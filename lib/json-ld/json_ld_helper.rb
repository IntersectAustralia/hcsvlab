module JsonLdHelper

public

  #
  #
  #
  def self::predefined_context_properties
    predefined_properties = HashWithIndifferentAccess.new
    predefined_properties['commonProperties'] = {'@id' => "http://purl.org/dada/schema/0.2#commonProperties"}
    predefined_properties['dada'] = {'@id' => "http://purl.org/dada/schema/0.2#"}
    predefined_properties['cld'] = {'@id' => "http://purl.org/cld/terms/"}
    predefined_properties['type'] = {'@id' => "http://purl.org/dada/schema/0.2#type"}
    predefined_properties['start'] = {'@id' => "http://purl.org/dada/schema/0.2#start"}
    predefined_properties['end'] = {'@id' => "http://purl.org/dada/schema/0.2#end"}
    predefined_properties['label'] = {'@id' => "http://purl.org/dada/schema/0.2#label"}
    predefined_properties["#{PROJECT_PREFIX_NAME}"] = {'@id' => "#{PROJECT_SCHEMA_LOCATION}"}

    predefined_properties
  end

  #
  # Returns an array of predefined vocabularies that should not be shown in the json ld schema.
  #
  def self::restricted_predefined_vocabulary
    avoid_context = []
    avoid_context << RDF::CC.to_uri
    avoid_context << RDF::CERT.to_uri
    avoid_context << RDF::DC11.to_uri
    avoid_context << RDF::DOAP.to_uri
    avoid_context << RDF::EXIF.to_uri
    avoid_context << RDF::GEO.to_uri
    avoid_context << RDF::GR.to_uri
    avoid_context << RDF::HCalendar.to_uri
    avoid_context << RDF::HCard.to_uri
    avoid_context << RDF::HTTP.to_uri
    avoid_context << RDF::ICAL.to_uri
    avoid_context << RDF::LOG.to_uri
    avoid_context << RDF::MA.to_uri
    avoid_context << RDF::MD.to_uri
    avoid_context << RDF::OG.to_uri
    avoid_context << RDF::OWL.to_uri
    avoid_context << RDF::PROV.to_uri
    avoid_context << RDF::PTR.to_uri
    avoid_context << RDF::RDFA.to_uri
    avoid_context << RDF::RDFS.to_uri
    avoid_context << RDF::REI.to_uri
    avoid_context << RDF::RSA.to_uri
    avoid_context << RDF::RSS.to_uri
    avoid_context << RDF::SIOC.to_uri
    avoid_context << RDF::SKOS.to_uri
    avoid_context << RDF::SKOSXL.to_uri
    avoid_context << RDF::V.to_uri
    avoid_context << RDF::VCARD.to_uri
    avoid_context << RDF::VOID.to_uri
    avoid_context << RDF::WDRS.to_uri
    avoid_context << RDF::WOT.to_uri
    avoid_context << RDF::XHTML.to_uri
    avoid_context << RDF::XHV.to_uri

    avoid_context << SPARQL::Grammar::SPARQL_GRAMMAR.to_uri

    avoid_context << "http://rdfs.org/sioc/types#"
    avoid_context
  end

  #
  # Returns a hash containing the values of a default Alveo json_ld context
  #
  def self::default_context
    predefined_properties = predefined_context_properties
    avoid_context = restricted_predefined_vocabulary
    vocab_hash = HashWithIndifferentAccess.new
    RDF::Vocabulary.each { |vocab|
      if !avoid_context.include?(vocab.to_uri) and vocab.to_uri.qname.present?
        prefix = vocab.to_uri.qname.first.to_s
        uri = vocab.to_uri.to_s
        vocab_hash[prefix] = {'@id' => uri}
      end
    }
    hash = {}
    predefined_properties.each_pair { |key, value| hash[key] = value }
    Hash[*vocab_hash.sort.flatten].each_pair { |key, value| hash[key] = value }
    hash
  end

  private

end