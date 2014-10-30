require 'spec_helper'
require "#{Rails.root}/lib/json-compare/orderless_json_comparer.rb"

describe 'Json compare' do
  describe 'Arrays Comparison with same list content but in different order' do
    it "should return Hash with empty diffs" do
      old = [{
                 "ID" => "545",
                 "Data" => {
                     "Something" => [{"Something" => [{"empty2" => 2}, {"empty" => 1}]}]
                 }
             }]
      new = [{
                 "ID" => "545",
                 "Data" => {
                     "Something" => [{"Something" => [{"empty" => 1}, {"empty2" => 2}]}]
                 }
             }]

      result = OrderlessJsonCompare.get_diff(old, new)


      result.should be_empty
    end
  end
end