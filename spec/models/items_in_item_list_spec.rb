require 'spec_helper'

describe ItemsInItemList do
  describe "Associations" do
    it { should belong_to(:item_list) }
  end
end
