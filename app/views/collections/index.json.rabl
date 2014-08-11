object false
node(:collections) { @collections.collect(&:flat_short_name) }
