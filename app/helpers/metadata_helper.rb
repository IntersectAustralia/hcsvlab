module MetadataHelper

  mattr_reader :lookup, :prefixes

private
  AUSNC_ROOT_URI = 'http://ns.ausnc.org.au/schemas/'
    ACE_BASE_URI     = AUSNC_ROOT_URI + 'ace/' unless const_defined?(:ACE_BASE_URI)
    AUSNC_BASE_URI   = AUSNC_ROOT_URI + 'ausnc_md_model/' unless const_defined?(:AUSNC_BASE_URI)
    AUSTLIT_BASE_URI = AUSNC_ROOT_URI + 'austlit/'
    COOEE_BASE_URI   = AUSNC_ROOT_URI + 'cooee/'
    GCSAUSE_BASE_URI = AUSNC_ROOT_URI + 'gcsause/'
    ICE_BASE_URI     = AUSNC_ROOT_URI + 'ice/'

  PURL_ROOT_URI = 'http://purl.org/'
    DC_TERMS_BASE_URI    = PURL_ROOT_URI + 'dc/terms/' unless const_defined?(:DC_TERMS_BASE_URI)
    DC_ELEMENTS_BASE_URI = PURL_ROOT_URI + 'dc/elements/1.1/' unless const_defined?(:DC_ELEMENTS_BASE_URI)
    PURL_BIBO_BASE_URI   = PURL_ROOT_URI + 'ontology/bibo/'
    PURL_VOCAB_BASE_URI  = PURL_ROOT_URI + 'vocab/bio/0.1/'

  OLAC_BASE_URI    = 'http://www.language-archives.org/OLAC/1.1/'
  FOAF_BASE_URI    = 'http://xmlns.com/foaf/0.1/'
  RDF_BASE_URI     = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  LOC_BASE_URI     = 'http://www.loc.gov/loc.terms/relators/'
  ALVEO_BASE_URI   = 'http://alveo.edu.au/vocabulary/'

  AUSTALK_BASE_URI = 'http://ns.austalk.edu.au/'

  @@lookup = {}
  @@prefixes = {
    ACE_BASE_URI         => "ACE",
    AUSNC_BASE_URI       => "AUSNC",
    AUSTLIT_BASE_URI     => "AUSTLIT",
    COOEE_BASE_URI       => "COOEE",
    GCSAUSE_BASE_URI     => "GCSAUSE",
    ICE_BASE_URI         => "ICE",

    DC_TERMS_BASE_URI    => "DC",
    DC_ELEMENTS_BASE_URI => "DC",
    PURL_BIBO_BASE_URI   => "PURL_BIBO",
    PURL_VOCAB_BASE_URI  => "PURL_VOCAB",

    FOAF_BASE_URI        => "FOAF",
    OLAC_BASE_URI        => "OLAC",
    RDF_BASE_URI         => "RDF",
    LOC_BASE_URI         => "LoC",

    AUSTALK_BASE_URI     => "AUSTALK",

    ALVEO_BASE_URI       => "Alveo"
  }

public
  #
  # AUSNC
  #
  AUDIENCE              = RDF::URI(AUSNC_BASE_URI + 'audience') unless const_defined?(:AUDIENCE)
  COMMUNICATION_CONTEXT = RDF::URI(AUSNC_BASE_URI + 'communication_context') unless const_defined?(:COMMUNICATION_CONTEXT)
  DOCUMENT              = RDF::URI(AUSNC_BASE_URI + 'document') unless const_defined?(:DOCUMENT)
  INTERACTIVITY         = RDF::URI(AUSNC_BASE_URI + 'interactivity') unless const_defined?(:INTERACTIVITY)
  LOCALITY_NAME         = RDF::URI(AUSNC_BASE_URI + 'locality_name')
  MODE                  = RDF::URI(AUSNC_BASE_URI + 'mode') unless const_defined?(:MODE)
  SPEECH_STYLE          = RDF::URI(AUSNC_BASE_URI + 'speech_style') unless const_defined?(:SPEECH_STYLE)

  @@lookup[AUDIENCE.to_s]              = prefixes[AUSNC_BASE_URI] + "_audience_facet"
  @@lookup[COMMUNICATION_CONTEXT.to_s] = prefixes[AUSNC_BASE_URI] + "_communication_context_facet"
  @@lookup[DOCUMENT.to_s]              = prefixes[AUSNC_BASE_URI] + "_document"
  @@lookup[INTERACTIVITY.to_s]         = prefixes[AUSNC_BASE_URI] + "_interactivity_facet"
  @@lookup[LOCALITY_NAME.to_s]         = prefixes[AUSNC_BASE_URI] + "_locality_name"
  @@lookup[MODE.to_s]                  = prefixes[AUSNC_BASE_URI] + "_mode_facet"
  @@lookup[SPEECH_STYLE.to_s]          = prefixes[AUSNC_BASE_URI] + "_speech_style_facet"

  #
  # AUSTLIT
  #
  LOCATION = RDF::URI(AUSTLIT_BASE_URI + 'location') unless const_defined?(:LOCATION)

  @@lookup[LOCATION.to_s] = prefixes[AUSTLIT_BASE_URI] + "_location"

  #
  # DC
  #
  IS_PART_OF             = RDF::URI(DC_TERMS_BASE_URI + 'isPartOf') unless const_defined?(:IS_PART_OF)
  TYPE                   = RDF::URI(DC_TERMS_BASE_URI + 'type') unless const_defined?(:TYPE)
  EXTENT                 = RDF::URI(DC_TERMS_BASE_URI + 'extent') unless const_defined?(:EXTENT)
  CREATED                = RDF::URI(DC_TERMS_BASE_URI + 'created') unless const_defined?(:CREATED)
  IDENTIFIER             = RDF::URI(DC_TERMS_BASE_URI + 'identifier') unless const_defined?(:IDENTIFIER)
  SOURCE                 = RDF::URI(DC_TERMS_BASE_URI + 'source') unless const_defined?(:SOURCE)
  TITLE                  = RDF::URI(DC_TERMS_BASE_URI + 'title') unless const_defined?(:TITLE)
  RIGHTS                 = RDF::URI(DC_TERMS_BASE_URI + 'rights') unless const_defined?(:RIGHTS)
  DESCRIPTION            = RDF::URI(DC_TERMS_BASE_URI + 'description') unless const_defined?(:DESCRIPTION)
  BIBLIOGRAPHIC_CITATION = RDF::URI(DC_TERMS_BASE_URI + 'bibliographicCitation') unless const_defined?(:BIBLIO_CITATION)

  @@lookup[IS_PART_OF.to_s]             = prefixes[DC_TERMS_BASE_URI] + "_is_part_of"
  @@lookup[EXTENT.to_s]                 = prefixes[DC_TERMS_BASE_URI] + "_extent"
  @@lookup[CREATED.to_s]                = prefixes[DC_TERMS_BASE_URI] + "_created"
  @@lookup[IDENTIFIER.to_s]             = prefixes[DC_TERMS_BASE_URI] + "_identifier"
  @@lookup[SOURCE.to_s]                 = prefixes[DC_TERMS_BASE_URI] + "_source"
  @@lookup[TITLE.to_s]                  = prefixes[DC_TERMS_BASE_URI] + "_title"
  @@lookup[TYPE.to_s]                   = prefixes[DC_TERMS_BASE_URI] + "_type_facet"
  @@lookup[RIGHTS.to_s]                 = prefixes[DC_TERMS_BASE_URI] + "_rights"
  @@lookup[DESCRIPTION.to_s]            = prefixes[DC_TERMS_BASE_URI] + "_description"
  @@lookup[BIBLIOGRAPHIC_CITATION.to_s] = prefixes[DC_TERMS_BASE_URI] + "_bibliographicCitation"

  #
  # OLAC
  #
  DISCOURSE_TYPE = RDF::URI(OLAC_BASE_URI + 'discourse_type') unless const_defined?(:DISCOURSE_TYPE)
  LANGUAGE       = RDF::URI(OLAC_BASE_URI + 'language') unless const_defined?(:LANGUAGE)

  @@lookup[DISCOURSE_TYPE.to_s] = prefixes[OLAC_BASE_URI] + "_discourse_type_facet"
  @@lookup[LANGUAGE.to_s]       = prefixes[OLAC_BASE_URI] + "_language_facet"

  #
  # RDF
  #
  RDF_TYPE = RDF::URI(RDF_BASE_URI + 'type') unless const_defined?(:RDF_TYPE)

  @@lookup[RDF_TYPE.to_s] = prefixes[RDF_BASE_URI] + "_type"


  #
  # LoC
  #
  LOC_RESPONSIBLE_PERSON = RDF::URI(LOC_BASE_URI + 'rpy') unless const_defined?(:LOC_RESPONSIBLE_PERSON)

  @@lookup[LOC_RESPONSIBLE_PERSON.to_s] = prefixes[LOC_BASE_URI] + "_responsible_person"

  #
  # AUSTALK
  #
  AUSTALK_COMPONENT     = RDF::URI(AUSTALK_BASE_URI + 'component') unless const_defined?(:AUSTALK_COMPONENT)
  AUSTALK_COMPONENTNAME = RDF::URI(AUSTALK_BASE_URI + 'componentName') unless const_defined?(:AUSTALK_COMPONENTNAME)
  AUSTALK_PROMPT        = RDF::URI(AUSTALK_BASE_URI + 'prompt') unless const_defined?(:AUSTALK_PROMPT)
  AUSTALK_PROTOTYPE     = RDF::URI(AUSTALK_BASE_URI + 'prototype') unless const_defined?(:AUSTALK_PROTOTYPE)
  AUSTALK_SESSION       = RDF::URI(AUSTALK_BASE_URI + 'session') unless const_defined?(:AUSTALK_SESSION)
  AUSTALK_TIMESTAMP     = RDF::URI(AUSTALK_BASE_URI + 'timestamp') unless const_defined?(:AUSTALK_TIMESTAMP)
  AUSTALK_VERSION       = RDF::URI(AUSTALK_BASE_URI + 'version') unless const_defined?(:AUSTALK_VERSION)

  #
  # HCSVLAB
  #
  COLLECTION = RDF::URI('collection_name_facet') unless const_defined?(:COLLECTION)
  IDENT      = RDF::URI(ALVEO_BASE_URI + 'ident') unless const_defined?(:IDENT)
  HAS_LICENCE= RDF::URI('has_licence') unless const_defined?(:HAS_LICENCE)
  INDEXABLE_DOCUMENT= RDF::URI(ALVEO_BASE_URI + 'indexable_document') unless const_defined?(:INDEXABLE_DOCUMENT)
  DISPLAY_DOCUMENT  = RDF::URI(ALVEO_BASE_URI + 'display_document') unless const_defined?(:DISPLAY_DOCUMENT)

  #
  # short_form - return a shortened form of the given uri (which will
  #              be .to_s'ed first)
  #
  def self::short_form(uri)
    uri = uri.to_s
    return @@lookup[uri] if @@lookup.has_key?(uri)
    @@prefixes.keys.each { |p|
      if uri.start_with?(p)
        uri = uri.sub(p, "#{@@prefixes[p]}_")
        return tidy(uri)
      end
    }
    return tidy(uri)
  end

  #
  # tidy - return a version of the given string with "special"
  #        characters replaced by "safe" ones
  #
  def self::tidy(uri)
    return uri.to_s.gsub(/\W/, '_').gsub(/_{2,}/, '_')
  end

end
