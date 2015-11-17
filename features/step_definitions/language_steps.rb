Given /^I have a language with code "([^"]*)" and name "([^"]*)"$/ do |code, name|
  FactoryGirl.create(:language, :code => code, :name => name)
end

Given /^I have languages/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:language, hash)
  end
end