class ItemsInItemList < ActiveRecord::Base
  belongs_to :item_list
  # We need to define :item_list as attr_accessible in order to allow mass-assign values to it
  attr_accessible :item, :item_list
end
