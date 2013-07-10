# -*- encoding : utf-8 -*-
Given /^I have done a search with term "([^\"]*)"$/ do |term|
  visit catalog_index_path(:q => term)
end

Given /^I have done a search with corpus "([^\"]*)"$/ do |term|
  visit catalog_index_path(:f => {'DC_is_part_of' => [term]})
end
