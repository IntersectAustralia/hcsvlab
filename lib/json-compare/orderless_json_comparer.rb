require "#{Rails.root}/lib/json-compare/orderless_json_compare.rb"

module OrderlessJsonCompare
  def self.get_diff(old, new, exclusion = [])
    comparer = JsonCompare::OrderlessComparer.new
    comparer.excluded_keys = exclusion
    comparer.compare_elements(old,new)
  end
end