object false
node(:num_collections) { @collections.size }
node(:collections) { @collections.collect {|c| collection_url(c.short_name)} }
