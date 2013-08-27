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
    When I make a JSON request for the catalog annotations page for "hcsvlab:1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"item_id":"hcsvlab:1","utterance":"http://example.org/catalog/hcsvlab:1/primary_text.json","annotations_found":2,"annotations":[{"type":"pageno","label":"11","start":2460.0,"end":2460.0},{"type":"ellipsis","label":"","start":2460.0,"end":2460.0}]}
    """

  Scenario: Request annotations for item that doesn't have annotations
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
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
    {"item_id":"hcsvlab:1","utterance":"http://example.org/catalog/hcsvlab:1/primary_text.json","annotations_found":1,"annotations":[{"type":"pageno","label":"11","start":2460.0,"end":2460.0}]}
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
    {"item_id":"hcsvlab:1","utterance":"http://example.org/catalog/hcsvlab:1/primary_text.json","annotations_found":1,"annotations":[{"type":"ellipsis","label":"","start":2460.0,"end":2460.0}]}
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