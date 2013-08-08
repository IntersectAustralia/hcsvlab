FactoryGirl.define do
  factory :collection_list do |cl|
   	cl.name "AUSNC " + Random.new.rand(1..10000).to_s
  end
end
