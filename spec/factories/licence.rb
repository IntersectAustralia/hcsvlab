FactoryGirl.define do
  factory :licence do |l|
   	l.name "Creative Commons"
   	l.text "Creative Commons Licence Terms"
   	l.type Licence::LICENCE_TYPE_PUBLIC
  end
end
