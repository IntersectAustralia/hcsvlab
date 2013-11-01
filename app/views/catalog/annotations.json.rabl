object @anns
object @annotates_document
node(:@context) { annotation_context_url }
data = []
common = { :annotates => @annotates_document }
common[:type] = @anns.first[:type].to_s if @anns.count > 0 and @anns.dup.filter(:type => @anns.first[:type].to_s).count == @anns.count
common[:label] = @anns.first[:label].to_s if @anns.count > 0 and @anns.dup.filter(:label => @anns.first[:label].to_s).count == @anns.count
node(:commonProperties) { common }

type_lookup = {"http://purl.org/dada/schema/0.2#SecondRegion" => "SecondAnnotation", "http://purl.org/dada/schema/0.2#UTF8Region" => "TextAnnotation"}

node(:annotations) do
  hash = {}
  @anns.each do |ann|
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