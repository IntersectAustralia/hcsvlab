FactoryGirl.define do
  factory :licence do |l|
    l.sequence(:name) { |n| "Creative Commons #{n}" }
   	l.text "Creative Commons Licence Terms"
   	l.type Licence::LICENCE_TYPE_PUBLIC
  end
end
