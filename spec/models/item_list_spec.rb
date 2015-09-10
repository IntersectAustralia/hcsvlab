require 'spec_helper'

describe ItemList do
  describe "Associations" do
    it { should have_many(:items) }
    it { should have_many(:items_in_item_lists) }
    it { should belong_to(:user) }
  end
end