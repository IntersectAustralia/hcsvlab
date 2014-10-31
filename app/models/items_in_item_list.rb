class ItemsInItemList < ActiveRecord::Base
  belongs_to :item_list
  belongs_to :item, foreign_key: :handle, primary_key: :handle
  # We need to define :item_list as attr_accessible in order to allow mass-assign values to it
  attr_accessible :handle, :item_list
end
