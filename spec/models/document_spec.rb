require 'spec_helper'

describe Document do
  before(:each) do
    Document.delete_all
  end
  after(:each) do
    Document.delete_all
  end

end