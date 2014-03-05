# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :items_in_item_list do |f|
    association f.item_list, factory: :item_list
    f.item "cooee:1"
  end
end
