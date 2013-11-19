object false

node(:@context) do
  hash = {}
  hash[:@base] = "http://purl.org/dada/schema/0.2/"
  hash[:annotations] = { :@id => "http://purl.org/dada/schema/0.2/annotations", :@container => "@list" }
  hash[:commonProperties] = {:@id => "http://purl.org/dada/schema/0.2/commonProperties"}
  hash[:type] = {:@id => "http://purl.org/dada/schema/0.2/type"}
  hash[:start] = {:@id => "http://purl.org/dada/schema/0.2/start"}
  hash[:end] = {:@id => "http://purl.org/dada/schema/0.2/end"}
  hash[:label] = {:@id => "http://purl.org/dada/schema/0.2/label"}
  hash[:annotates] = {:@id => "http://purl.org/dada/schema/0.2/annotates"}

  @vocab_hash.each_pair { |key, value |
    hash[key] = value
  }

  hash
end