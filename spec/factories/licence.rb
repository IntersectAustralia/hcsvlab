FactoryGirl.define do
  factory :licence do |l|
   	l.name "Creative Commons " + Random.new.rand(1..10000).to_s
   	l.text "Creative Commons Licence Terms"
   	l.type Licence::LICENCE_TYPE_PUBLIC
  end
end
