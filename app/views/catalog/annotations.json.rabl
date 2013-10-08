object @item
object @document
object @type
object @label
if @item.nil?
  node(:error) { "Item does not exist with given id" }
elsif @item.datastreams["annotationSet1"].nil?
  node(:error) { "No annotation file for this item" }
else
  node(:@vocab) { annotation_context_url }

  data = []
  uri = buildURI(@item.id, 'annotationSet1')
  repo = RDF::Repository.load(uri)
  corpus = @document[MetadataHelper::short_form(MetadataHelper::COLLECTION)].first
  queryConfig = YAML.load_file(Rails.root.join("config", "sparql.yml"))

  q = "
    PREFIX dada:<http://purl.org/dada/schema/0.2#>
    PREFIX cp:<" + (queryConfig[corpus]['corpus_prefix'] unless queryConfig[corpus].nil?).to_s + ">
    select * where
    {
      ?anno a dada:Annotation .
      OPTIONAL { ?anno cp:val ?label . }
      OPTIONAL { ?anno dada:type ?type . }
      OPTIONAL { 
        ?anno dada:targets ?loc .
        OPTIONAL { ?loc a ?region . }
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

  # hacky way to find the "primary" document, need to make this standard in RDF
  if !@item.primary_text.content.nil?
    annotates_document = "#{catalog_primary_text_url(@item.id, format: :json)}"
  else
    uris = [MetadataHelper::IDENTIFIER, MetadataHelper::TYPE, MetadataHelper::EXTENT, MetadataHelper::SOURCE]
    documents = item_documents(@document, uris)
    if(documents.present?)
      annotates_document = "#{catalog_document_url(@document.id, documents.first[MetadataHelper::IDENTIFIER])}"
    else
      annotates_document = "#{catalog_url(@item)}"
    end
  end

  common = { :annotates => annotates_document }
  common[:type] = anns.first[:type].to_s if anns.count > 0 and anns.dup.filter(:type => anns.first[:type].to_s).count == anns.count
  common[:label] = anns.first[:label].to_s if anns.count > 0 and anns.dup.filter(:label => anns.first[:label].to_s).count == anns.count
  node(:commonProperties) { common }

  type_lookup = {"http://purl.org/dada/schema/0.2#MillisecondRegion" => "MillisecondAnnotation", "http://purl.org/dada/schema/0.2#UTF8Region" => "TextAnnotation"}
  node(:annotations) do
    hash = {}
    anns.each do |ann|
      hash[:@type] = type_lookup[ann[:region].to_s]
      hash[:@id] = ann[:anno].to_s
      hash[:type] = ann[:type].to_s
      hash[:label] = ann[:label].to_s
      hash[:start] = ann[:start].to_f
      hash[:end] = ann[:end].to_f
      data << hash.clone
    end
    data
  end
end