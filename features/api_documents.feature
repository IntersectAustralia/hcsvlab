Feature: Accessing, creating, and deleting documents via API
  As a Researcher,
  I want to use the API to get metadata relating to a particular Item.

  Background:
    Given I have the usual roles and permissions
    And I have users
      | email                        | first_name | last_name |
      | data_owner@intersect.org.au  | Data_Owner | One       |
      | researcher1@intersect.org.au | Researcher | One       |
    And "data_owner@intersect.org.au" has role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has an api token

#ToDo: update all @api_update_document tests so that they use the new format for adding items as in the refactored @api_add_item story

   #ToDo: Add this (add_doc) context to all API ingest tests, since it is the proper 'Alveo Json-ld schema' context with the addition of the 'dc:terms' mapping to the dc namespace
   @api_add_document
  Scenario: Add a document with document content as JSON
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON post request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"@context":"https://app.alveo.edu.au/schema/json-ld","alveo:metadata":{"dc:type":"Text","dc:identifier":"document2.txt","dc:title":"document2#Text","alveo:fulltext":"Text"}} |
    Then the file "document2.txt" should exist in the directory for the collection "test"
    And the document "document2.txt" under item "item1" in collection "test" should exist in the database
    And Sesame should contain a document with uri "http://example.org/catalog/test/item1/document/document2.txt" in collection "test"
    And Sesame should contain a document with file_name "document2.txt" in collection "test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Added the document document2.txt to item item1 in collection test"}
    """

  @api_add_document
  Scenario: Add a document with a referenced file
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON post request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"@context":"https://app.alveo.edu.au/schema/json-ld","alveo:metadata":{"dc:type":"Text","dc:identifier":"document2.txt","dc:title":"document2#Text","dcterms:source":"file:///data/test_collections/ausnc/test/document2.txt"}} |
    Then the document "document2.txt" under item "item1" in collection "test" should exist in the database
    And Sesame should contain a document with uri "http://example.org/catalog/test/item1/document/document2.txt" in collection "test"
    And Sesame should contain a document with file_path "/data/test_collections/ausnc/test/document2.txt" in collection "test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Added the document document2.txt to item item1 in collection test"}
    """

  @api_add_document
  Scenario: Add a document with an empty uploaded file
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON multipart request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                         | metadata |
      | "test/samples/api/blank.txt" | {"@context":"https://app.alveo.edu.au/schema/json-ld","alveo:metadata":{"dc:type":"Text","dc:identifier":"blank.txt","dc:title":"blank#Text"} |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Uploaded file blank.txt is not present or empty."}
    """

  @api_add_document
  Scenario: Add a document with an uploaded file
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON multipart request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | metadata |
      #| "test/samples/cooee/1-001-plain.txt" | { "@context": {"dcterms": "http://purl.org/dc/terms/"}, "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:identifier": "1-001-plain.txt", "dcterms:title": "1-001#Text", "dcterms:type": "Text" } |
      | "test/samples/cooee/1-001-plain.txt" | {"@context":"https://app.alveo.edu.au/schema/json-ld","alveo:metadata":{"dc:type":"Text","dc:identifier":"1-001-plain.txt","dc:title":"1-001#Text"} |
    Then the file "1-001-plain.txt" should exist in the directory for the collection "test"
    And the document "1-001-plain.txt" under item "item1" in collection "test" should exist in the database
    And Sesame should contain a document with uri "http://example.org/catalog/test/item1/document/1-001-plain.txt" in collection "test"
    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Added the document 1-001-plain.txt to item item1 in collection test"}
    """


  #@api_add_document
  #Scenario: Add a document and @id is automatically overwritten
  #  Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
  #    | name | collection_metadata |
  #    | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
  #  And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
  #    | items |
  #    | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
  #  When I make a JSON post request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
  #    | document_content | metadata |
  #    | "Hello World!"   | { "@context":{"dc":{"@id":"http://purl.org/dc/terms/"},"dcterms":"http://purl.org/dc/terms/","foaf":{"@id":"http://xmlns.com/foaf/0.1/"}}, "@id": "http://document2.txt", "@type": "foaf:Document", "dcterms:identifier": "document2.txt", "dcterms:title": "document2#Text", "dcterms:type": "Text" } |
  #  Then Sesame should not contain a document with uri "http://document2.txt" in collection "test"
  #  And Sesame should contain a document with uri "http://example.org/catalog/test/item1/document/document2.txt" in collection "test"
  #  And I should get a 200 response code
  #  And the JSON response should be:
  #  """
  #  {"success":"Added the document document2.txt to item item1 in collection test"}
  #  """

  @api_add_document
  Scenario: Add a document with invalid metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    # Invalid metadata is space in dcterms: title
    When I make a JSON post request for the add document to item page for "test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | document_content | metadata |
      | "Hello World!"   | { "@context":{"dc":{"@id":"http://purl.org/dc/terms/"},"dcterms":"http://purl.org/dc/terms/","foaf":{"@id":"http://xmlns.com/foaf/0.1/"}}, "@id": "http://document2.txt", "@type": "foaf:Document", "dcterms:identifier":"document2.txt", "dcterms: title": "document2#Text", "dcterms:type": "Text" } |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Invalid metadata"}
    """

    #ToDo: test validation of invalid metadata

    #ToDo: test validation regarding empty document content, empty uploaded files

    #ToDo: clarify whether referenced files should just point to the referenced file or make a copy of it (since delete document deletes the file)

  @api_delete_document
  Scenario: When removing a document the user must be the collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "test" page with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"User is unauthorised"}
    """

  @api_delete_document
  Scenario: Removing a non-existing document should result in an error
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "false_document.raw" from "item "item1" in collection "test" page with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested document not found"}
    """

  @api_delete_document
  Scenario: Removing a non-existing document should result in an error
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "document1.txt" from "item "false_item" in collection "test" page with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested item not found"}
    """

  @api_delete_document
  Scenario: Removing a document from a non-existing item should result in an error
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "false_collection" page with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested collection not found"}
    """

  @api_delete_document  @javascript
  Scenario: Removing a document returns the right success message
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "test" page with the API token for "data_owner@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Deleted the document document1.txt from item item1 in collection test"}
    """

  @api_delete_document  @javascript
  Scenario: Removing a document removes that document from the filesystem, database and Sesame
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "test" page with the API token for "data_owner@intersect.org.au"
    Then the file "document1.txt" should not exist in the directory for the collection "test"
    And the document "document1.text" under item "item1" in collection "test" should not exist in the database
    And Sesame should not contain a document with file_name "document1.txt" in collection "test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Deleted the document document1.txt from item item1 in collection test"}
    """

  @api_delete_document  @javascript
  Scenario: Removing a document removes that document from Solr and is no longer visible on the collection items page
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "test" page with the API token for "data_owner@intersect.org.au"
    And I go to the catalog page for "test:item1"
    Then I should see "Item Details"
    And I should see "Identifier: item1"
    And I should see "Collection: test"
    And I should not see "Documents: document1.txt"
    And I should not see "document1.txt"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Deleted the document document1.txt from item item1 in collection test"}
    """

  @api_delete_document  @javascript
  Scenario: Removing a document from an item with two documents
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "Hello World" }, { "identifier": "document2.txt", "content": "Foo Bar" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" }, { "@id": "document2.txt", "@type": "foaf:Document", "dcterms:identifier": "document2.txt", "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON delete request for the delete document "document1.txt" from "item "item1" in collection "test" page with the API token for "data_owner@intersect.org.au"
    And I go to the catalog page for "test:item1"
    Then I should see "Item Details"
    And I should see "Identifier: item1"
    And I should see "Collection: test"
    And I should not see "Documents: document1.txt, document2.txt"
    And I should see "Documents: document2.txt"
    And I should see "Documents"
    And I should see "document2.txt"
    And I should not see "document1.txt"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Deleted the document document1.txt from item item1 in collection test"}
    """