FactoryGirl.define do
  factory :licence do |l|
    l.sequence(:name) { |n| "Creative Commons #{n}" }
   	l.text "Creative Commons Licence Terms"
   	l.private false
  end
end
