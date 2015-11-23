Feature: Creating Documents
  As a Data Owner or Admin,
  I want to add a document to an existing item via the web app

  Background:
    Given I have the usual roles and permissions
    And I have a user "admin@intersect.org.au" with role "admin"
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And I have a user "researcher@intersect.org.au" with role "researcher"
    And I have languages
      | code  | name      |
      | eng   | English   |
      | zza   | Zaza      |
      | xyj   | Mayi-Yapi |

  Scenario: Verify add document button is visible for collection owner
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    When I am on the catalog page for "cooee:1-001"
    Then I should see link "Add New Document" to "/add-document/cooee/1-001"

  Scenario Outline: Verify add document button is not visible for users other than the collection owner
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "<user>"
    When I am on the catalog page for "cooee:1-001"
    Then I should not see link "Add New Item" to "/add-document/cooee/1-001"
  Examples:
    | user |
    | admin@intersect.org.au      |
    | researcher@intersect.org.au |

  Scenario: Verify add document button goes to new document form page
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    When I am on the catalog page for "cooee:1-001"
    When I follow element with id "add_new_document"
    Then I should be on the add document page for "cooee:1-001"

  Scenario Outline: Verify users other than the collection owner are not authorised to load add document page
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "<user>"
    When I am on the add document page for "cooee:1-001"
    Then I should see "You are not authorised to access this page."
  Examples:
    | user |
    | admin@intersect.org.au      |
    | researcher@intersect.org.au |

  Scenario: Verify add document page has expected form fields
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    When I am on the add document page for "cooee:1-001"
    Then I should see "Add Document"
    And I should see "Please select a file:"
    And I should see "Document Metadata"
    And I should see "Language: "
    And I should see "Additional Metadata"
    And I should see "See the RDF Names of searchable fields for examples of accepted metadata field names."
    And I should see link "searchable fields" to "/catalog/searchable_fields"
    And I should see "Note: If the context for a field you want to enter is not available in the default schema then you must provide the full URI for that metadata field."
    And I should see link "default schema" to "/schema/json-ld"
    And I should see "Add Metadata Field"
    And I should see button with text "Add Metadata Field"
    And I should see link "Cancel" to "/catalog/cooee/1-001"
    And I should see button "Create"

  Scenario: Verify add metadata name/value fields not visible by default
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    When I am on the add document page for "cooee:1-001"
    Then I should not see "Name: Value: "

  @javascript
  Scenario: Verify add metadata name/value fields are visible after clicking add metadata field button
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "cooee:1-001"
    When I click "Add Metadata Field"
    Then the "additional_key[]" field should contain ""
    And the "additional_value[]" field should contain ""

  Scenario: Verify uploading a document file is required
    Given I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "cooee:1-001"
    And I press "Create"
    Then I should be on the add document page for "cooee:1-001"
    And I should see "Required field 'document file' is missing"

  @create_collection
  Scenario: Verify required language field has default value selected
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    When I attach the file "test/samples/api/sample1.txt" to "document_file"
    And I press "Create"
    Then I should not see "Required field 'language' is missing"

  @create_collection
  Scenario: Create a document and verify it exists in the filesystem, database and Sesame
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/sample1.txt" to "document_file"
    And I press "Create"
    Then the file "sample1.txt" should exist in the directory for the collection "test"
    And the document "sample1.txt" under item "item1" in collection "test" should exist in the database
    And Sesame should contain a document with uri "http://www.example.com/catalog/test/item1/document/sample1.txt" in collection "test"
    And Sesame should contain a document with file_name "sample1.txt" in collection "test"

  @create_collection
  Scenario Outline: Verify a document with spaces in its filename cannot be created
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/<file>" to "document_file"
    And I press "Create"
    Then I should see "Spaces are not permitted in the file name: <file> ×"
    And I should be on the add document page for "test:item1"
  Examples:
    | file                     |
    | filename space.txt       |
    | filename with spaces.txt |

  @create_collection
  Scenario: Create a document with just the required fields
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/sample1.txt" to "document_file"
    And I press "Create"
    Then I should see "Added the document sample1.txt to item item1 in collection test ×"
    And I should be on the catalog page for "test:item1"
    And I should see "Documents"
    And I should see "Filename        Type         Size"
    And I should see "document1.txt   Text"
    And I should see "sample1.txt     unlabelled   12 B"

  @javascript @create_collection
  Scenario Outline: Create a document with a set of additional metadata
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/sample1.txt" to "document_file"
    #Todo: get select2 selection working in cucumber test
    #    And I select2 "zza - Zaza" from "language_select"
    When I click "Add Metadata Field"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    Then I should see "Added the document sample1.txt to item item1 in collection test ×"
    And I should be on the catalog page for "test:item1"
    And I should see "Documents"
    And I should see "Filename        Type        Size"
    And I should see "document1.txt   Text"
    And I should see "sample1.txt     unlabelled  12 B"
  Examples:
    | key         | value      |
    | dc:created  | 10/11/2015 |
    | dc:cre ated | 10/11/2015 |

  @javascript @create_collection
  Scenario Outline: Verify providing an empty metadata field returns an error response
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/sample1.txt" to "document_file"
    When I click "Add Metadata Field"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    Then I should be on the add document page for "test:item1"
    And I should see "<response>"
  Examples:
    | key        | value      | response |
    |            | 10/11/2015 | An additional metadata field is missing a name             |
    | dc:created |            | Additional metadata field 'dc:created' is missing a value |

  @javascript @create_collection
  Scenario: Verify form is re-populated with previous input if an error occurs
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add document page for "test:item1"
    And I attach the file "test/samples/api/sample1.txt" to "document_file"
    When I click "Add Metadata Field"
    And I fill in "additional_key[]" with "dc:created"
    And I fill in "additional_value[]" with ""
    And I press "Create"
    Then I should be on the add document page for "test:item1"
    And I should see "Additional metadata field 'dc:created' is missing a value"
    And I should see "eng - English"
    And the "additional_key[]" field should contain "dc:created"
    And the "additional_value[]" field should contain ""
