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
      doc.doc_type = 'Audio'
      doc.mime_type = "application/foo"
      doc.save
      pid = doc.id

      doc2 = Document.find(pid)
      doc2.file_name.should eq 'foo.txt'
      doc2.doc_type.should eq 'Audio'
      doc2.mime_type.should eq 'application/foo'
    end

  end

end