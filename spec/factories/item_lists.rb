# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_list do
    name "itemList"
    association :user, factory: :user
  end
end
