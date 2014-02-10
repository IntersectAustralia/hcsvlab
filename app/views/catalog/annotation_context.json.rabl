object false

node(:@context) do
  hash = {}

  @predefinedProperties.each_pair { |key, value |
    hash[key] = value
  }

  Hash[*@vocab_hash.sort.flatten].each_pair { |key, value |
    hash[key] = value
  }

  hash
end