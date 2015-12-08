# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    collection
    handle "test:collection"
    uri "http://www.test.org/collections"
  end
end
