require 'rake'
require 'spec_helper'
require "#{Rails.root}/spec/support/ingest_helper.rb"

describe UserAnnotation do

  ANNOTATION_SAMPLE_FILE = "#{Rails.root}/test/samples/annotations/upload_annotation_sample.json"
  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

  describe 'Successfully uploaded annotation' do

    it 'Should successfully upload an annotation collection in the right context' do
      ingest_one("cooee", "1-001")
      user = FactoryGirl.create(:user, :status => 'A', :email => "hcsvlab_test_user@intersect.org.au")

      uploadedFile = ActionDispatch::Http::UploadedFile.new({filename:"upload_annotation_sample.json", tempfile: ANNOTATION_SAMPLE_FILE})

      created = UserAnnotation.create_new_user_annotation(user, "cooee:1-001", uploadedFile)
      created.should eq true

      createdAnnotation = UserAnnotation.find_by_item_identifier("cooee:1-001")
      createdAnnotation.should_not be nil

      annotationCollectionId = createdAnnotation.annotationCollectionId

      createdAnnotation.item_identifier.should eq "cooee:1-001"
      createdAnnotation.user.email.should eq "hcsvlab_test_user@intersect.org.au"
      createdAnnotation.original_filename.should eq "upload_annotation_sample.json"
      annotationCollectionId.should_not be nil

      server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository("cooee")

      # First we will verify that the AnnotationCollection was created successfully
      sparqlQuery ="""
        SELECT *
        WHERE {
          <#{annotationCollectionId}> ?predicate ?object .
        }
      """
      result = repository.sparql_query(sparqlQuery)

      mapResult = {}
      result.map{|aSolution| mapResult[aSolution['predicate']] = aSolution['object']}

      mapResult[RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")].should eq RDF::URI("http://purl.org/dada/schema/0.2#AnnotationCollection")
      mapResult[RDF::URI("http://purl.org/dc/terms/created")].should_not be nil
      mapResult[RDF::URI("http://purl.org/dada/schema/0.2#annotates")].should eq RDF::URI("http://ns.ausnc.org.au/corpora/cooee/items/1-001")
      mapResult[RDF::URI("http://purl.org/dc/terms/creator")].should eq RDF::URI("#{PROJECT_BASE_URI}users/#{Digest::MD5.hexdigest(user.email)}")

      # Now we will verify that the annotations in the AnnotationCollection were created successfully and with the
      # correct context.
      sparqlQuery ="""
        SELECT *
        FROM <#{annotationCollectionId}>
        WHERE {
           ?annotationId <http://purl.org/dada/schema/0.2#partof> <#{annotationCollectionId}> .
        }
      """
      result = repository.sparql_query(sparqlQuery)

      annotationIds = result.map {|aSolution| aSolution['annotationId']}

      annotationIds.size.should eq 5
    end

    it 'Should correctly assign annotation values' do
      ingest_one("cooee", "1-001")
      user = FactoryGirl.create(:user, :status => 'A', :email => "hcsvlab_test_user@intersect.org.au")

      uploadedFile = ActionDispatch::Http::UploadedFile.new({filename:"upload_annotation_sample.json", tempfile: ANNOTATION_SAMPLE_FILE})

      UserAnnotation.create_new_user_annotation(user, "cooee:1-001", uploadedFile)
      createdAnnotation = UserAnnotation.find_by_item_identifier("cooee:1-001")
      annotationCollectionId = createdAnnotation.annotationCollectionId

      server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository("cooee")

      sparqlQuery ="""
        SELECT *
        FROM <#{annotationCollectionId}>
        WHERE {
           ?annotationId <http://purl.org/dada/schema/0.2#partof> ?object .
        }
      """
      result = repository.sparql_query(sparqlQuery)
      annotationIds = result.map {|aSolution| aSolution['annotationId']}

      annotationIds.each do |anAnnotationId|

        # Verify that each annotation has its corresponding locator
        sparqlQuery ="""
        SELECT *
        FROM <#{annotationCollectionId}>
        WHERE {
           <#{anAnnotationId.to_s}> <http://purl.org/dada/schema/0.2#targets> ?locator .
        }
        """
        result = repository.sparql_query(sparqlQuery)
        result.each.first['locator'].should eq RDF::URI("#{anAnnotationId}/Locator")

        # Verify that fields values are correct.
        sparqlQuery ="""
          SELECT *
          FROM <#{annotationCollectionId}>
          WHERE {
             <#{anAnnotationId.to_s}/Locator> ?subject ?object .
          }
        """
        result = repository.sparql_query(sparqlQuery)
        mapResult = {}
        result.map{|aSolution| mapResult[aSolution['subject']] = aSolution['object']}

        mapResult[RDF.type.to_uri].should eq RDF::URI("http://purl.org/dada/schema/0.2#UTF8Region")
        mapResult[RDF::URI("http://purl.org/dada/schema/0.2#type")].to_s.should eq "pageno"
        mapResult[RDF::URI("http://purl.org/dada/schema/0.2#start")].should eq mapResult[RDF::URI("http://purl.org/dada/schema/0.2#end")]
      end


    end
  end

  describe 'Unsuccessfully uploaded annotation' do
    it 'should raise an exception if the graph section is empty or not present' do
      ingest_one("cooee", "1-001")
      user = FactoryGirl.create(:user, :status => 'A', :email => "hcsvlab_test_user@intersect.org.au")

      uploadedFile = ActionDispatch::Http::UploadedFile.new({filename:"upload_empty_graph_annotation_sample.json",
                                                             tempfile: "#{Rails.root}/test/samples/annotations/upload_empty_graph_annotation_sample.json"})
      created = UserAnnotation.create_new_user_annotation(user, "cooee:1-001", uploadedFile)

      created.should be false
    end

    it 'should raise an exception if the context section is wrong' do
      ingest_one("cooee", "1-001")
      user = FactoryGirl.create(:user, :status => 'A', :email => "hcsvlab_test_user@intersect.org.au")

      uploadedFile = ActionDispatch::Http::UploadedFile.new({filename:"upload_empty_graph_annotation_sample.json",
                                                             tempfile: "#{Rails.root}/test/samples/annotations/wrong_context_annotation_sample.json"})
      created = UserAnnotation.create_new_user_annotation(user, "cooee:1-001", uploadedFile)

      created.should be false
    end
  end

end