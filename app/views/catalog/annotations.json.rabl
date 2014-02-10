object @anns
object @annotates_document
node(:@context) { annotation_context_url }
data = []

common = { :annotates => @annotates_document }
@anns[:commonProperties].each_pair do |key, value|
  common[key] = value if !value.nil?
end
node(:commonProperties) { common }

node(:annotations) do
  @anns[:annotations].each_pair do |annId, ann|
    hash = {}
    hash[:@id] = annId.to_s

    ann.each_pair do |key, value|
      hash[key] = value
    end

    data << hash.clone
  end
  data
end