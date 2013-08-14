FactoryGirl.define do
  factory :collection_list do |cl|
    cl.sequence(:name) { |n| "AUSNC #{n}" }
  end
end
