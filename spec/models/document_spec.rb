require 'spec_helper'

describe Document do
  before(:each) do
    Document.delete_all
  end
  after(:each) do
    Document.delete_all
  end

  describe "Document Descriptive Metadata" do

    it "should persist metadata about a Document" do
      doc = Document.new
      doc.file_name = 'foo.txt'
      doc.type = 'Audio'
      doc.mime_type = "application/foo"
      doc.save
      pid = doc.pid

      doc2 = Document.find(pid)
      doc2.file_name[0].should eq 'foo.txt'
      doc2.type[0].should eq 'Audio'
      doc2.mime_type[0].should eq 'application/foo'
    end

  end

end