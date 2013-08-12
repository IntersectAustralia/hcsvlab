object @item
object @document
object @type
object @label
if @item.nil?
  node(:error) { "Item does not exist with given id" }
elsif @item.datastreams["annotationSet1"].nil?
  node(:error) { "No annotation file for this item" }
else
  node(:item_id) { @item.id }
  data = []
  uri = buildURI(@item.id, 'annotationSet1')
  repo = RDF::Repository.load(uri)
  corpus = @document[MetadataHelper::short_form(MetadataHelper::COLLECTION)].first
  queryConfig = YAML.load_file(Rails.root.join("config", "sparql.yml"))

  if !@item.primary_text.content.nil?
    node(:utterance) { catalog_primary_text_url(@item.id, format: :json) }
  else
    uris = [MetadataHelper::IDENTIFIER, MetadataHelper::TYPE, MetadataHelper::EXTENT, MetadataHelper::SOURCE]
    documents = item_documents(@document, uris)
    if(documents.present?)
      node(:utterance) { catalog_document_url(@document.id, documents.first[MetadataHelper::IDENTIFIER]) }
    else
      node(:utterance) { "" }
    end
  end

  q = "
    PREFIX dada:<http://purl.org/dada/schema/0.2#>
    PREFIX cp:<" + queryConfig[corpus]['corpus_prefix'] + ">
    select * where
    {
      ?anno a dada:Annotation .
      OPTIONAL { ?anno cp:val ?label . }
      OPTIONAL { ?anno dada:type ?type . }
      OPTIONAL { 
        ?anno dada:targets ?loc .
        OPTIONAL { ?loc dada:start ?start . }
        OPTIONAL { ?loc dada:end ?end . }
      }
      "

  if @type.present?
    q << "?anno dada:type '" + CGI.escape(@type).to_s.strip + "' ."
  end
  if @label.present?
    q << "?anno cp:val '" + CGI.escape(@label).to_s.strip + "' ."
  end

  q << "}"

  query = SPARQL.parse(q)
  anns = query.execute(repo)

  node(:annotations_found) { anns.count }

  node(:annotations) do
    hash = {}
    anns.each do |ann|

      hash[:type] = ann[:type].to_s
      hash[:label] = ann[:label].to_s
      hash[:start] = ann[:start].to_f
      hash[:end] = ann[:end].to_f
      data << hash.clone
    end
    data
  end
end