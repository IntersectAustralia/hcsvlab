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
  corpus = @document["DC_is_part_of"].first
  queryConfig = YAML.load_file(Rails.root.join("config", "sparql.yml"))

  q = "
    PREFIX dada:<http://purl.org/dada/schema/0.2#>
    select * where
    {
      ?anno_coll a dada:AnnotationCollection .
      ?i dada:annotates ?item .
    } "
  query = SPARQL.parse(q)
  item = query.execute(repo)
  puts item.first[:item]
  node(:item) { File.basename(item.first[:item].to_s) }

  q = "
    PREFIX dada:<http://purl.org/dada/schema/0.2#>
    PREFIX cp:<" + queryConfig[corpus]['corpus_prefix'] + ">
    select * where
    { 
      ?anno a dada:Annotation .
      ?anno cp:val ?label .
      ?anno dada:targets ?loc .
      ?loc dada:start ?start .
      ?loc dada:end ?end . "
  q.sub! "corpus_name", corpus.to_s
  if @type.present?
    q << "?anno dada:type '" + @type.to_s.strip + "' ."
  end
  if @label.present?
    q << "?anno cp:val '" + @label.to_s.strip + "' ."
  end
  q << "}"

  query = SPARQL.parse(q)
  segs = query.execute(repo)
  node(:segments_found) { segs.count }

  node(:segments) do
    hash = {}
    segs.each do |seg|
      hash[:label] = seg[:label].to_s
      hash[:start] = seg[:start].to_f
      hash[:end] = seg[:end].to_f
      data << hash.clone
    end
    data
  end
end