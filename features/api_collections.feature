Feature: Accessing, creating collections via API
  As a Researcher,
  I want to use the API to get metadata relating to a particular collection

  Background:
    Given I have the usual roles and permissions
    And I have users
      | email                        | first_name | last_name |
      | admin@intersect.org.au       | Admin      | One       |
      | researcher1@intersect.org.au | Researcher | One       |
      | data_owner@intersect.org.au  | Data_Owner | One       |
    And "admin@intersect.org.au" has role "admin"
    And "admin@intersect.org.au" has an api token
    And "data_owner@intersect.org.au" has role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has an api token

  Scenario: Access collection details via the API
    Given I ingest "cooee:1-001"
    And I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$..['alveo:metadata']['alveo:collection_name']" with the text "cooee"

  Scenario: Access collection details via the API matches JSON-LD
    Given I ingest "cooee:1-001"
    And I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":"http://example.org/schema/json-ld","alveo:collection_url":"http://example.org/catalog/cooee","alveo:metadata":{"alveo:collection_name":"cooee","rdf:type":"http://purl.org/dc/dcmitype/Collection","dc11:title":"Corpus of Oz Early English","dc:alternative":"COOEE","dc:abstract":"Material to be included had to meet with a regional and a temporal criterion. The latter required texts to have been produced between 1788 and 1900 in order to become eligible for COOEE. It was mandatory for a text to have been written in Australia, New Zealand or Norfolk Island. But in a few cases, other localities were allowed. For example, if a person who was a native Australian or who had lived in Australia for a considerable time, wrote a shipboard diary or travelled in other countries.","dc:extent":"1353 text samples","dc:language":"eng","dc:itemType":"text with tags","dc:itemFormat":"Letters, published materials in book form, historical texts","dc:temporal":"1788-1900","dc:created":"2004","http://purl.org/cld/terms/dateItemsCreated":"1788-1900","dc11:creator":"Clemens Fritz","dc11:rights":"All rights reserved to Clemens Fritz","dc:accessRights":"See AusNC Terms of Use","loc:OWN":"None. Individual owner is Clemens Fritz.","alveo:sparql_endpoint":"http://example.org/sparql/cooee"}}
    """

  Scenario: Access collection details via the API for non-existant collection
    Given I make a JSON request for the collection page for "non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"not-found"}
    """

  @api_create_collection
  Scenario: Create new collection via the API as a researcher
    When I make a JSON post request for the collections page with the API token for "researcher1@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"Permission Denied: Your role within the system does not have sufficient privileges to be able to create a collection. Please contact an Alveo administrator."}
    """

  @api_create_collection
  Scenario: Create new collection via the API as a data owner
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "alveo:metadata": {"@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"}} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection via the API as a data owner using JSON-LD with URI for context
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context":"http://example.org/schema/json-ld","rdf:type":"http://purl.org/dc/dcmitype/Collection","dc:title":"Corpus of Oz Early English","dc:alternative":"COOEE","dc:abstract":"Material to be included had to meet with a regional and a temporal criterion. The latter required texts to have been produced between 1788 and 1900 in order to become eligible for COOEE. It was mandatory for a text to have been written in Australia, New Zealand or Norfolk Island. But in a few cases, other localities were allowed. For example, if a person who was a native Australian or who had lived in Australia for a considerable time, wrote a shipboard diary or travelled in other countries.","dc:extent":"1353 text samples","dc:language":"eng","dc:itemType":"text with tags","dc:itemFormat":"Letters, published materials in book form, historical texts","dc:temporal":"1788-1900","dc:created":"2004","http_purl_org_cld_terms_dateItemsCreated":"1788-1900","dc11:creator":"Clemens Fritz","dc11:rights":"All rights reserved to Clemens Fritz","dc:accessRights":"See AusNC Terms of Use","loc:OWN":"None. Individual owner is Clemens Fritz."} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """
    And I make a JSON request for the collection page for "test" with the API token for "data_owner@intersect.org.au"
    Then the JSON response should be:
    """
    {"@context":"http://example.org/schema/json-ld","alveo:collection_url":"http://example.org/catalog/test","alveo:metadata":{"alveo:collection_name":"test","dc11:creator":"Clemens Fritz","dc11:rights":"All rights reserved to Clemens Fritz","dc:abstract":"Material to be included had to meet with a regional and a temporal criterion. The latter required texts to have been produced between 1788 and 1900 in order to become eligible for COOEE. It was mandatory for a text to have been written in Australia, New Zealand or Norfolk Island. But in a few cases, other localities were allowed. For example, if a person who was a native Australian or who had lived in Australia for a considerable time, wrote a shipboard diary or travelled in other countries.","dc:accessRights":"See AusNC Terms of Use","dc:alternative":"COOEE","dc:created":"2004","dc:extent":"1353 text samples","dc:itemFormat":"Letters, published materials in book form, historical texts","dc:itemType":"text with tags","dc:language":"eng","dc:temporal":"1788-1900","dc:title":"Corpus of Oz Early English","loc:OWN":"None. Individual owner is Clemens Fritz.","rdf:type":"http://purl.org/dc/dcmitype/Collection","alveo:sparql_endpoint":"http://example.org/sparql/test"}}
    """

  @api_create_collection
  Scenario: Create new collection via the API as an admin
    When I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection via the API with duplicate name
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://other.collection/test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://other.collection/test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "Another test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"A collection with the name 'test' already exists"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without JSON params
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" without JSON params
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name and metadata parameters not found"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without name param
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | collection_metadata |
      | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name parameter not found"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without the metadata param
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name |
      | Test |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"metadata parameter not found"}
    """

  @api_create_collection
  Scenario: Create new collection assigns collection owner to api key user
    # admin user is used since the default collection owner in test env is data_owner@intersect.org.au
    When I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the owner of collection "test" should be "admin@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection assigns collection owner to api key user who is also the default collection owner
    When I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the owner of collection "test" should be "data_owner@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection assigns collection owner to api key user even if they specify an owner in the metadata
    # assign the collection owner to be "researcher1@intersect.org.au" in the collection metadata (using the marcel:rpy tag)
    When I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:rpy": "researcher1@intersect.org.au"} |
    Then I should get a 200 response code
    And the owner of collection "test" should be "admin@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection automatically generates the catalog URL
    When I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/" }, "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection" } |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection overwrites any supplied catalog URI with the catalog URL
    When I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection" } |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'test' (http://example.org/catalog/test) created"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a full set of metadata, specifying to replace existing metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | true      | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "An updated test collection", "marcrel:OWN": "Data Owner"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a full set of metadata, without specifying to replace or update existing metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | collection_metadata |
      | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "An updated test collection", "marcrel:OWN": "Data Owner"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a partial set of metadata, specifying to replace the metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | true      | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:title": "An updated test collection", "dc:subject": "Updated Language"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a partial set of metadata, specifying to update the metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:title": "An updated test collection", "dc:subject": "Updated Language"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a minimal set of metadata, specifying to update the metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/"}, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with the least amount of metadata possible, specifying to update the metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"@id": "http://collection.test", "http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with the least amount of metadata possible, specifying to replace the metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | true      | {"http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should not see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with a random URI doesn't report an error
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"@id": "http://random.uri", "http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should not see "Title: A test collection"
    And I should see "Owner: Data Owner"
    And I should see "Title: An updated test collection"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection without being the collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "researcher1@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"@id": "http://collection.test", "http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: A test collection"
    And I should see "Owner: Data Owner"
    And I should not see "Title: An updated test collection"
    And I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"User is unauthorised"}
    """

  @api_edit_collection
  Scenario: Edit a collection without providing a URI, specifying to replace
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | true      | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@type": "dcmitype:Collection", "dc:title": "An updated test collection", "dc:subject": "Updated Language"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection without providing a URI, specifying to update
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """

  @api_edit_collection
  Scenario: Edit a collection with invalid metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | replace   | collection_metadata |
      | false     | {"http://purl.org/dc/elements/1.1/ title": "An updated test collection"} |
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Invalid metadata"}
    """

  @api_edit_collection
  Scenario: Updating a collection doesn't append the metadata onto matching existing metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON put request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | collection_metadata |
      | {"http://purl.org/dc/elements/1.1/title": "An updated test collection"} |
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    And I follow "test"
    Then the file "test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should not see "Title: A test collection"
    And I should see "Title: An updated test collection"
    And I should not see "Title: An updated test collection, A test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection test"}
    """