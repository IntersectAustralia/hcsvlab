# -*- encoding : utf-8 -*-
Given /^I have done a search with term "([^\"]*)"$/ do |term|
  visit catalog_index_path(:q => term)
end

Given /^I have done a search with collection "([^\"]*)"$/ do |term|
  visit catalog_index_path(:f => {'HCSvLab_collection_facet' => [term]})
end
