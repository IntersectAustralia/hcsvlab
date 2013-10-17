Feature: Browsing via API
  As a Researcher,
  I want to use the API to get metadata relating to a particular Item.

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                        | first_name | last_name |
      | researcher1@intersect.org.au | Researcher | One       |
      | data_owner@intersect.org.au  | Data_Owner | One       |
    And "data_owner@intersect.org.au" has role "data owner"
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has an api token
    And "researcher1@intersect.org.au" has item lists
      | name   |
      | Test 1 |
      | Test 2 |

  Scenario Outline: Visit pages with an API token OUTSIDE the header and HTML format doesn't authenticate
    When I make a request for <page> with the API token for "researcher1@intersect.org.au" outside the header
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                            | code |
    | the item lists page             | 302  |
    | the item list page for "Test 1" | 302  |
    | the collection page for "cooee" | 302  |
    | the home page                   | 200  |

  Scenario Outline: Visit pages with an API token OUTSIDE the header and JSON format still doesn't authenticate
    When I make a JSON request for <page> with the API token for "researcher1@intersect.org.au" outside the header
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                            | code |
    | the item lists page             | 401  |
    | the item list page for "Test 1" | 401  |
    | the collection page for "cooee" | 401  |
    | the home page                   | 406  |

  Scenario Outline: Visit pages with an API token and HTML format doesn't authenticate
    When I make a request for <page> with the API token for "researcher1@intersect.org.au"
    Then I should get a <code> response code
  Examples:
    | page                            | code |
    | the item lists page             | 302  |
    | the item list page for "Test 1" | 302  |
    | the collection page for "cooee" | 302  |
    | the home page                   | 200  |

  Scenario Outline: Visit pages with an API token and JSON format authenticates
    When I make a JSON request for <page> with the API token for "researcher1@intersect.org.au"
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                            | code |
    | the item lists page             | 200  |
    | the item list page for "Test 1" | 200  |
    | the home page                   | 406  |

  Scenario Outline: Visit pages with an API token and JSON format to access someone else's item list
    Given I have users
      | email                        | first_name | last_name |
      | researcher2@intersect.org.au | Researcher | Two       |
    And "researcher2@intersect.org.au" has role "researcher"
    And "researcher2@intersect.org.au" has item lists
      | name   |
      | Test 3 |
      | Test 4 |
    When I make a JSON request for <page> with the API token for "researcher1@intersect.org.au"
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                            | code |
    | the item list page for "Test 3" | 403  |
    | the item list page for "Test 4" | 403  |

  Scenario Outline: Visit pages without an API token and JSON format
    When I make a JSON request for <page> without an API token
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                            | code |
    | the item lists page             | 401  |
    | the item list page for "Test 1" | 401  |
    | the home page                   | 406  |

  Scenario Outline: Visit pages with an invalid API token and JSON format
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON request for <page> with an invalid API token
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                                                               | code |
    | the item lists page                                                | 401  |
    | the item list page for "Test 1"                                    | 401  |
    | the collection page for "cooee"                                    | 401  |
    | the catalog page for "hcsvlab:1"                                   | 401  |
    | the catalog primary text page for "hcsvlab:1"                      | 401  |
    | the document content page for file "blah.txt" for item "hcsvlab:1" | 401  |
    | the catalog annotations page for "hcsvlab:1"                       | 401  |
    | the home page                                                      | 406  |

  Scenario: Get item lists for researcher
    When I make a JSON request for the item lists page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$..num_items" with a length of 2
    And the JSON response should have "$..name" with a length of 2
    And the JSON response should have "$..name" with the text "Test 1"
    And the JSON response should have "$..name" with the text "Test 2"

  Scenario: Get item lists for researcher with no item lists
    Given I have users
      | email                        | first_name | last_name |
      | researcher2@intersect.org.au | Researcher | Two       |
    And "researcher2@intersect.org.au" has role "researcher"
    And "researcher2@intersect.org.au" has an api token
    When I make a JSON request for the item lists page with the API token for "researcher2@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    []
    """
  Scenario: Get item list detail for researcher
    When I make a JSON request for the item list page for "Test 1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$..name" with the text "Test 1"

  Scenario: Get item list detail for researcher for item list that doesn't exist
    When I make a JSON request for the item list page for item list "666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get item details
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path           | text                                                   |
      | $..annotations_url  | http://example.org/catalog/hcsvlab:1/annotations.json  |
      | $..primary_text_url | http://example.org/catalog/hcsvlab:1/primary_text.json |

  Scenario: Get item details should not return fields used for authorization
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should not have "$..discover_access_group_ssim"
    And the JSON response should not have "$..read_access_group_ssim"
    And the JSON response should not have "$..edit_access_group_ssim"
    And the JSON response should not have "$..discover_access_person_ssim"
    And the JSON response should not have "$..read_access_person_ssim"
    And the JSON response should not have "$..edit_access_person_ssim"



  Scenario: Get item details for non-existent item (TODO: should return 404, probably?)
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog page for "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Get annotations for item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"@vocab":"http://example.org/schema/json-ld","commonProperties":{"annotates":"http://example.org/catalog/hcsvlab:1/primary_text.json"},"annotations":[{"@type":"TextAnnotation","@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/0","type":"pageno","label":"11","start":2460.0,"end":2460.0},{"@type":"TextAnnotation","@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1","type":"ellipsis","label":"","start":2460.0,"end":2460.0}]}
    """

  Scenario: Get annotation context
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    And "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the annotation context page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":{"@base":"http://purl.org/dada/schema/0.2/","annotations":{"@id":"http://purl.org/dada/schema/0.2/annotations","@container":"@list"},"commonProperties":{"@id":"http://purl.org/dada/schema/0.2/commonProperties"},"type":{"@id":"http://purl.org/dada/schema/0.2/type"},"start":{"@id":"http://purl.org/dada/schema/0.2/start"},"end":{"@id":"http://purl.org/dada/schema/0.2/end"},"label":{"@id":"http://purl.org/dada/schema/0.2/label"},"annotates":{"@id":"http://purl.org/dada/schema/0.2/annotates"}}}
    """

  Scenario: Request annotations for item that doesn't have annotations
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "hcsvlab:2" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations for item that doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON request for the catalog annotations page for "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get specific annotations for item by label
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au" with params
      | label |
      | 11    |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"@vocab":"http://example.org/schema/json-ld","commonProperties":{"annotates":"http://example.org/catalog/hcsvlab:1/primary_text.json","type":"pageno","label":"11"},"annotations":[{"@type":"TextAnnotation","@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/0","type":"pageno","label":"11","start":2460.0,"end":2460.0}]}
    """

  Scenario: Get specific annotations for item by type
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au" with params
      | type     |
      | ellipsis |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"@vocab":"http://example.org/schema/json-ld","commonProperties":{"annotates":"http://example.org/catalog/hcsvlab:1/primary_text.json","type":"ellipsis"},"annotations":[{"@type":"TextAnnotation","@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1","type":"ellipsis","label":"","start":2460.0,"end":2460.0}]}
    """

  Scenario: Download primary_text from item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog primary text page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then I should get the primary text for "cooee:1-001"

  Scenario: Download primary_text from item that doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog primary text page for "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download document which exists
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "hcsvlab:2" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the response should be:
    """
    This is the plain text file 1-002-plain.txt.
    
    """


  Scenario: Download document that doesn't exist for item that does exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the document content page for file "blah.txt" for item "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download document where the item doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the document content page for file "blah.txt" for item "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """
  Scenario: Access collection details via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    And I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$..collection_name" with the text "cooee"

  Scenario: Access collection details via the API for non-existant collection
    Given I make a JSON request for the collection page for id "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Get item details with no Accept header should default to json
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a request with no accept header for the catalog page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path           | text                                                   |
      | $..annotations_url  | http://example.org/catalog/hcsvlab:1/annotations.json  |
      | $..primary_text_url | http://example.org/catalog/hcsvlab:1/primary_text.json |

  Scenario: Search for simple term in all metadata
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I ingest "ice:S2B-035" with id "hcsvlab:3"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | monologue  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/hcsvlab:3"]}
    """

  Scenario: Search for two simple term in all metadata joined with AND via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "ice:S2B-035" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata               |
      | University AND Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/hcsvlab:4"]}
    """

  Scenario: Search for two simple term in all metadata joined with OR via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "ice:S2B-035" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata              |
      | University OR Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/hcsvlab:3","http://example.org/catalog/hcsvlab:4"]}
    """

  Scenario: Search for term with asterisk in all metadata via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | Correspon* |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/hcsvlab:1","http://example.org/catalog/hcsvlab:2"]}
    """

  Scenario: Search metadata with field:value via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                          |
      | AUSNC_discourse_type_tesim:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/hcsvlab:1"]}
    """

  Scenario: Search metadata with quotes via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                       |
      | date_group_facet:"1880 - 1889" |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/hcsvlab:2"]}
    """

  Scenario: Search metadata with ranges via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata       |
      | [1810 TO 1899] |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/hcsvlab:2"]}
    """

  Scenario: Search metadata via the API using a badly formed query
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata |
      | :        |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"bad-query"}
    """

  Scenario: Add items to a new item list via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                                                           |
      | cooee | ["http://example.org/catalog/hcsvlab:1","http://example.org/catalog/hcsvlab:2"] |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"2 items added to new item list cooee"}
    """

  Scenario: Add items to an existing item list via the API
    Given "researcher1@intersect.org.au" has item lists
      | name  |
      | cooee |
    Given I ingest "cooee:1-002" with id "hcsvlab:1"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                    |
      | cooee | ["http://example.org/catalog/hcsvlab:1"] |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"1 items added to existing item list cooee"}
    """

  Scenario: Add items to an item list via the API without specifying a name
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | items                                    |
      | ["http://example.org/catalog/hcsvlab:1"] |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name parameter not found"}
    """

  Scenario: Add items to an item list via the API without specifying a name or items to add
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name |
      |      |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name and items parameters not found"}
    """