object false
node(:num_collections) { @collections.size }
node(:collections) { @collections.collect(&:flat_short_name) }
