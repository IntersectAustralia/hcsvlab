object false
node(:count) { @collections.size }
node(:collections) { @collections.collect(&:flat_short_name) }
