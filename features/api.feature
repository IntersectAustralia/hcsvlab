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
    | page                                                                 | code |
    | the item lists page                                                  | 401  |
    | the item list page for "Test 1"                                      | 401  |
    | the collection page for "cooee"                                      | 401  |
    | the catalog page for "cooee:1-001"                                   | 401  |
    | the catalog primary text page for "cooee:1-001"                      | 401  |
    | the document content page for file "blah.txt" for item "cooee:1-001" | 401  |
    | the catalog annotations page for "cooee:1-001"                       | 401  |
    | the home page                                                        | 406  |

  Scenario: Get item lists for researcher
    When I make a JSON request for the item lists page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$..num_items" with a length of 2
    And the JSON response should have "$..name" with a length of 2
    And the JSON response should have "$..name" with the text "Test 1"
    And the JSON response should have "$..name" with the text "Test 2"

  Scenario: Get item lists for researcher
    Given "data_owner@intersect.org.au" has item lists
      | name     | shared |
      | Shared 1 | true   |
    When I make a JSON request for the item lists page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have "$.own..num_items" with a length of 2
    And the JSON response should have "$.own..name" with a length of 2
    And the JSON response should have "$.own..name" with the text "Test 1"
    And the JSON response should have "$.own..name" with the text "Test 2"
    And the JSON response should have "$.shared..name" with a length of 1
    And the JSON response should have "$.shared..name" with the text "Shared 1"


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

  Scenario: Get item details for cooee item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                       | text                                                      |
      | $..['dc:created']               | 10/11/1791                                                |
      | $..['dc:identifier']            | 1-001                                                     |
      | $..['dc:isPartOf']              | cooee                                                     |
      | $..['dc:type']                  | Original, Raw, Text                                       |
      | $..['ausnc:itemwordcount']      | 924                                                       |
      | $..['ausnc:discourse_type']     | letter                                                    |
      | $..['olac:language']            | eng                                                       |
      | $..['olac:speaker']             | 1-001addressee, 1-001author                               |
      | $..['cooee:register']           | Private Written                                           |
      | $..['cooee:texttype']           | Private Correspondence                                    |
      | $..['bibo:pages']               | 10-11                                                     |
      | $..['hcsvlab:sparqlEndpoint']   | http://example.org/sparql/cooee                           |
      | $..['hcsvlab:annotations_url']  | http://example.org/catalog/cooee/1-001/annotations.json   |
      | $..['hcsvlab:primary_text_url'] | http://example.org/catalog/cooee/1-001/primary_text.json  |

  Scenario: Get item details for austalk item
    Given I ingest "austalk:1_1014_1_11_001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | austalk         | read        |
    When I make a JSON request for the catalog page for "austalk:1_1014_1_11_001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                       | text                                                                |
      | $..['dc:created']               | Fri Sep 09 14:18:48 2011                                            |
      | $..['dc:identifier']            | 1_1014_1_11_001                                                     |
      | $..['dc:isPartOf']              | 1_1014_1_11                                                         |
      | $..['dc:type']                  | Audio                                                               |
      | $..['olac:speaker']             | 1_1014                                                              |
      | $..['austalk:component']        | 11                                                                  |
      | $..['austalk:componentName']    | calibration                                                         |
      | $..['austalk:prompt']           | Turn right 90  (face right wall)  2                                 |
      | $..['austalk:prototype']        | 11_1                                                                |
      | $..['austalk:session']          | 1                                                                   |
      | $..['austalk:version']          | 1.6                                                                 |
      | $..['hcsvlab:sparqlEndpoint']   | http://example.org/sparql/austalk                                   |
      | $..['hcsvlab:primary_text_url'] | No primary text found                                               |
    And the JSON response should not have
      | json_path                       | text                                                                |
      | $..['hcsvlab:annotations_url']  | http://example.org/catalog/austalk/1_1014_1_11_001/annotations.json |

  Scenario: Get item details should not return fields used for authorization
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
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
    When I make a JSON request for the catalog page for "cooee:something" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download primary_text from item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog primary text page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
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
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "cooee:1-002" with the API token for "researcher1@intersect.org.au"
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
    When I make a JSON request for the document content page for file "blah.txt" for item "cooee:1-001" with the API token for "researcher1@intersect.org.au"
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
    When I make a JSON request for the document content page for file "blah.txt" for item "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
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
    Given I make a JSON request for the collection page for "non-exists" with the API token for "researcher1@intersect.org.au"
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
    When I make a request with no accept header for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                       | text                                                     |
      | $..['hcsvlab:annotations_url']  | http://example.org/catalog/cooee/1-001/annotations.json  |
      | $..['hcsvlab:primary_text_url'] | http://example.org/catalog/cooee/1-001/primary_text.json |

  Scenario: Search for simple term in all metadata
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I ingest "ice:S2B-035" with id "hcsvlab:3"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | auslit          | read        |
      | ice             | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | monologue  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/ice/S2B-035"]}
    """

  Scenario: Search for two simple term in all metadata joined with AND via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "ice:S2B-035" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
      | ice             | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata               |
      | University AND Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/austlit/bolroma"]}
    """

  Scenario: Search for two simple term in all metadata joined with OR via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "ice:S2B-035" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
      | ice             | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata              |
      | University OR Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/austlit/adaessa","http://example.org/catalog/austlit/bolroma"]}
    """

  Scenario: Search for term with asterisk in all metadata via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | Correspon* |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/1-002"]}
    """

  Scenario: Search metadata with field:value via the API using solr field name
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                          |
      | AUSNC_discourse_type_tesim:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata              |
      | discourse_type:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name and all metadata search
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                                  |
      | Correspondence AND discourse_type:letter  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name and all metadata search with asterisk
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                              |
      | Correspon* AND discourse_type:letter  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with quotes via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                       |
      | date_group_facet:"1880 - 1889" |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/austlit/adaessa"]}
    """

  Scenario: Search metadata with ranges via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata       |
      | [1810 TO 1899] |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/austlit/adaessa"]}
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

  Scenario: Testing permissions when searching using the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "ice:S2B-035" with id "hcsvlab:2"
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | ice             | read        |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | eng        |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/cooee/1-001", "http://example.org/catalog/ice/S2B-035"]}
    """

  Scenario: Add items to a new item list via the API
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                                                               |
      | cooee | ["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/1-002"] |
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
      | name  | items                                       |
      | cooee | ["http://example.org/catalog/cooee/1-002"]  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"1 items added to existing item list cooee"}
    """

  Scenario: Add items to an item list via the API without specifying a name
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | items                                    |
      | ["http://example.org/catalog/cooee/any"] |
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

  Scenario: Add items to an item list via the API including non-existent items
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                                                                     |
      | cooee | ["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/non-exists"]  |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"1 items added to new item list cooee"}
    """

  Scenario: Add items to an item list via the API sending in items as string
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                   |
      | cooee | http://example.org/catalog/hcsvlab/any  |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"items parameter not an array"}
    """

  Scenario: Download items metadata and files in Zip format including non-existent items
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I make a JSON post request for the download_items page with the API token for "researcher1@intersect.org.au" with JSON params
      | format   | items                                                                                    |
      | zip      | ["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/non-exists"] |
    Then I should get a 200 response code

  Scenario: Download items metadata and files in Warc format
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    And "researcher1@intersect.org.au" has item lists
      | name   |
      | Test 1 |
    And the item list "Test 1" has items cooee:1-001
    And I wait 5 seconds
    Given I make a WARC request for the item list page for "Test 1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

  ###########################################################################################################
  #### RETRIEVE ANNOTATIONS TESTS                                                                        ####
  ###########################################################################################################

  Scenario: Get annotation context
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    And "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the annotation context page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":{"@base":"http://purl.org/dada/schema/0.2#","annotations":{"@id":"http://purl.org/dada/schema/0.2#annotations","@container":"@list"},"commonProperties":{"@id":"http://purl.org/dada/schema/0.2#commonProperties"},"type":{"@id":"http://purl.org/dada/schema/0.2#type"},"start":{"@id":"http://purl.org/dada/schema/0.2#start"},"end":{"@id":"http://purl.org/dada/schema/0.2#end"},"label":{"@id":"http://purl.org/dada/schema/0.2#label"},"annotates":{"@id":"http://purl.org/dada/schema/0.2#annotates"},"hcsvlab":{"@id":"http://hcsvlab.org.au/schema/"},"ace":{"@id":"http://ns.ausnc.org.au/schemas/ace/"},"ausnc":{"@id":"http://ns.ausnc.org.au/schemas/ausnc_md_model/"},"austalk":{"@id":"http://ns.austalk.edu.au/"},"austlit":{"@id":"http://ns.ausnc.org.au/schemas/austlit/"},"bibo":{"@id":"http://purl.org/ontology/bibo/"},"cooee":{"@id":"http://ns.ausnc.org.au/schemas/cooee/"},"dc":{"@id":"http://purl.org/dc/terms/"},"foaf":{"@id":"http://xmlns.com/foaf/0.1/"},"gcsause":{"@id":"http://ns.ausnc.org.au/schemas/gcsause/"},"ice":{"@id":"http://ns.ausnc.org.au/schemas/ice/"},"olac":{"@id":"http://www.language-archives.org/OLAC/1.1/"},"purl":{"@id":"http://purl.org/"},"rdf":{"@id":"http://www.w3.org/1999/02/22-rdf-syntax-ns#"},"schema":{"@id":"http://schema.org/"},"xsd":{"@id":"http://www.w3.org/2001/XMLSchema#"}}}
    """

  Scenario: Get annotation context without API token
    Given I make a JSON request for the annotation context page without an API token
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":{"@base":"http://purl.org/dada/schema/0.2#","annotations":{"@id":"http://purl.org/dada/schema/0.2#annotations","@container":"@list"},"commonProperties":{"@id":"http://purl.org/dada/schema/0.2#commonProperties"},"type":{"@id":"http://purl.org/dada/schema/0.2#type"},"start":{"@id":"http://purl.org/dada/schema/0.2#start"},"end":{"@id":"http://purl.org/dada/schema/0.2#end"},"label":{"@id":"http://purl.org/dada/schema/0.2#label"},"annotates":{"@id":"http://purl.org/dada/schema/0.2#annotates"},"hcsvlab":{"@id":"http://hcsvlab.org.au/schema/"},"ace":{"@id":"http://ns.ausnc.org.au/schemas/ace/"},"ausnc":{"@id":"http://ns.ausnc.org.au/schemas/ausnc_md_model/"},"austalk":{"@id":"http://ns.austalk.edu.au/"},"austlit":{"@id":"http://ns.ausnc.org.au/schemas/austlit/"},"bibo":{"@id":"http://purl.org/ontology/bibo/"},"cooee":{"@id":"http://ns.ausnc.org.au/schemas/cooee/"},"dc":{"@id":"http://purl.org/dc/terms/"},"foaf":{"@id":"http://xmlns.com/foaf/0.1/"},"gcsause":{"@id":"http://ns.ausnc.org.au/schemas/gcsause/"},"ice":{"@id":"http://ns.ausnc.org.au/schemas/ice/"},"olac":{"@id":"http://www.language-archives.org/OLAC/1.1/"},"purl":{"@id":"http://purl.org/"},"rdf":{"@id":"http://www.w3.org/1999/02/22-rdf-syntax-ns#"},"schema":{"@id":"http://schema.org/"},"xsd":{"@id":"http://www.w3.org/2001/XMLSchema#"}}}
    """

  Scenario: Get annotations for item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "hcsvlab:annotates":"http://example.org/catalog/cooee/1-001/primary_text.json"
      },
      "hcsvlab:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/0",
          "label":"11",
          "type":"pageno",
          "@type":"TextAnnotation",
          "end":"2460",
          "start":"2460"
        },
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type":"ellipsis",
          "@type":"TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item with different @type
    Given I ingest "cooee:1-002" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-002" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "hcsvlab:annotates":"http://example.org/catalog/cooee/1-002/primary_text.json"
      },
      "hcsvlab:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-002/0",
          "label":"ai",
          "type":"phonetic",
          "@type":"SecondAnnotation",
          "end":"1.1548",
          "start":"1.1348"
        }
      ]
    }
    """

  Scenario: Request annotations for item that doesn't have annotations
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotations page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations for item that doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON request for the catalog annotations page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotation properties for an item
    Given I ingest "cooee:1-002" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotation properties page for "cooee:1-002" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "item_url": "http://example.org/catalog/cooee/1-002",
      "annotation_properties": [
        {
          "uri": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
          "shortened_uri": "rdf:type"
        },
        {
          "uri": "http://ns.ausnc.org.au/schemas/cooee/val",
          "shortened_uri": "ns1:val"
        },
        {
          "uri": "http://purl.org/dada/schema/0.2#partof",
          "shortened_uri": "dada:partof"
        },
        {
          "uri": "http://purl.org/dada/schema/0.2#targets",
          "shortened_uri": "dada:targets"
        },
        {
          "uri": "http://purl.org/dada/schema/0.2#type",
          "shortened_uri": "dada:type"
        },
        {
          "uri": "http://purl.org/dada/schema/0.2#end",
          "shortened_uri": "dada:end"
        },
        {
          "uri": "http://purl.org/dada/schema/0.2#start",
          "shortened_uri": "dada:start"
        }
      ]
    }
    """

  Scenario: Get annotation properties for an item that doesn't have annotations
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotation properties page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations properties for item that doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON request for the catalog annotation properties page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotation types for an item
    Given I ingest "cooee:1-002" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotation types page for "cooee:1-002" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "item_url": "http://example.org/catalog/cooee/1-002",
      "annotation_types": [
        "phonetic"
      ]
    }
    """

  Scenario: Get annotation types for an item that doesn't have annotations
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotation types page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations types for item that doesn't exist
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON request for the catalog annotation types page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get specific annotations for item by label
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | label |
      | 11    |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "hcsvlab:annotates":"http://example.org/catalog/cooee/1-001/primary_text.json"
      },
      "hcsvlab:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/0",
          "label":"11",
          "type":"pageno",
          "@type":"TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get specific annotations for item by type
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | type     |
      | ellipsis |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "hcsvlab:annotates":"http://example.org/catalog/cooee/1-001/primary_text.json"
      },
      "hcsvlab:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type":"ellipsis",
          "@type":"TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item using extra properties
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | dada:start | dada:targets                                             |
      | 2460       | http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1L |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "@context": "http://example.org/schema/json-ld",
      "commonProperties": {
        "hcsvlab:annotates": "http://example.org/catalog/cooee/1-001/primary_text.json"
      },
      "hcsvlab:annotations": [
        {
          "@id": "http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type": "ellipsis",
          "@type": "TextAnnotation",
          "end": "2460",
          "start": "2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item using invalid property
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | property |
      | test     |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"error in query parameters"}
    """

  Scenario: Get annotations for item including a user uploaded one
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 200 response code
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have 5 user uploaded annotations
    And the JSON response should have the following annotations properties in any order:
        | label   | type    |  @type         | end   | start |
        | 11      | pageno  | TextAnnotation | 2460  | 2460  |
        |         | ellipsis| TextAnnotation | 2460  | 2460  |
        | 449     | pageno  | TextAnnotation | 421   | 421   |
        | ...     | pageno  | TextAnnotation | 2524  | 2524  |
        | 451     | pageno  | TextAnnotation | 6309  | 6309  |
        | ...     | pageno  | TextAnnotation | 6598  | 6598  |
        | 450     | pageno  | TextAnnotation | 3475  | 3475  |


  ###########################################################################################################
  #### UPLOAD ANNOTATIONS TESTS                                                                          ####
  ###########################################################################################################

  Scenario: Successfully uploaded user annotation
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 200 response code

  Scenario: Upload annotation to non existing item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON multipart request for the catalog annotations page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 404 response code

  Scenario: Upload blank annotation to an item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                      | Type                      |
      | file  |         | test/samples/annotations/blank_upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Uploaded file is not present or empty."}
    """

  Scenario: Upload same annotation file twice
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 200 response code

    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                 | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json   | application/octet-stream  |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"File already uploaded."}
    """

  Scenario: Upload malformed annotation to an item
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                          | Type                      |
      | file  |         | test/samples/annotations/malformed_upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 500 response code
    And the JSON response should be:
    """
    {"error":"Error uploading file malformed_upload_annotation_sample.json."}
    """

  Scenario: Uploaded user annotation for an item I have no read access
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name  | Content | Filename                                                | Type                      |
      | file  |         | test/samples/annotations/upload_annotation_sample.json  | application/octet-stream  |
    Then I should get a 403 response code

  ###########################################################################################################
  #### SPARQL ENDPOINT TESTS                                                                             ####
  ###########################################################################################################

  Scenario: Send sparql query without specifying the query.
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query  |
      |        |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Parameter 'query' is required."}
    """

  Scenario: Send sparql query to a collection I have no access.
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog sparql page for collection "austlit" with the API token for "researcher1@intersect.org.au" with params
      | query                       |
      | select * where {?s ?p ?o}   |
    Then I should get a 403 response code


#
# In the near future we might allow the SERVICE keyword in the query. I'll leave this test for that purpose
#
#  Scenario: Send sparql query to a collection I have no access by using the service keyword.
#    Given I ingest "cooee:1-001" with id "hcsvlab:1"
#    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
#    Given I have user "researcher1@intersect.org.au" with the following groups
#      | collectionName  | accessType  |
#      | cooee           | read        |
#    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
#      | query                                                                                                                            |
#      | select * where {SERVICE <http://localhost:8984/openrdf-sesame/repositories/austlit> {?s <http://purl.org/dc/terms/isPartOf> ?o}} |
#    Then I should get a 403 response code


  Scenario: Send sparql query to a collection that does not exists.
    When I make a JSON request for the catalog sparql page for collection "notExists" with the API token for "researcher1@intersect.org.au" with params
      | query                      |
      | select * where {?s ?p ?o}  |
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"collection not-found"}
    """

  Scenario: Send sparql query to retrieve an item identifier
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query                                                                                                        |
      | select * where {<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/identifier> ?o} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "head":{
        "vars":[
          "o"
        ]
      },
      "results":{
        "bindings":[
          {
            "o":{
              "type":"literal",
              "value":"1-001"
            }
          }
        ]
      }
    }
    """
#
#
# In the near future we might allow the SERVICE keyword in the query. I'll leave this test for that purpose
#
#  Scenario: Send sparql query to retrieve an item identifier by using Service keyword
#    Given I ingest "cooee:1-001" with id "hcsvlab:1"
#    Given I have user "researcher1@intersect.org.au" with the following groups
#      | accessType  |
#      | read        |
#    When I make a JSON request for the catalog sparql page with the API token for "researcher1@intersect.org.au" with params
#      | query                                                                                                                                                                             |
#      | select * where {SERVICE <http://localhost:8984/openrdf-sesame/repositories/cooee> {<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/identifier> ?o}}  |
#    Then I should get a 200 response code
#    And the JSON response should be:
#    """
#    {
#      "head":{
#        "vars":[
#          "o"
#        ]
#      },
#      "results":{
#        "bindings":[
#          {
#            "o":{
#              "type":"literal",
#              "value":"1-001"
#            }
#          }
#        ]
#      }
#    }
#    """

  Scenario: Send sparql query to retrieve all items' collection name
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query                                                      |
      | select * where {?s <http://purl.org/dc/terms/isPartOf> ?o} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "head":{
        "vars":[
          "s",
          "o"
        ]
      },
      "results":{
        "bindings":[
          {
            "s":{
              "type":"uri",
              "value":"http://ns.ausnc.org.au/corpora/cooee/items/1-001"
            },
            "o":{
              "type":"uri",
              "value":"http://ns.ausnc.org.au/corpora/cooee"
            }
          },
          {
            "s":{
              "type":"uri",
              "value":"http://ns.ausnc.org.au/corpora/cooee/items/1-002"
            },
            "o":{
              "type":"uri",
              "value":"http://ns.ausnc.org.au/corpora/cooee"
            }
          }
        ]
      }
    }
    """

  Scenario: Send sparql query to retrieve an item identifier by specifying collection and also using wrong Service with Silent keyword
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query                                                                                                                                                                          |
      | SELECT ?o {{<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/isPartOf> ?o} UNION {SERVICE SILENT <http://localhost:8984/openrdf-sesame/repositories/notexists> {?s ?p ?o}}} |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Service keyword is forbidden in queries."}
    """

#
# In the near future we might allow the SERVICE keyword in the query. I'll leave these 2 tests for that purpose
#
#  Scenario: Send sparql query to retrieve an item identifier by specifying collection and also using Service keyword
#    Given I ingest "cooee:1-001" with id "hcsvlab:1"
#    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
#    Given I have user "researcher1@intersect.org.au" with the following groups
#      | collectionName  | accessType  |
#      | cooee           | read        |
#      | austlit         | read        |
#    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
#      | query                                                                                                                                                                          |
#      | SELECT * {{<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/isPartOf> ?o} UNION {SERVICE <http://localhost:8984/openrdf-sesame/repositories/austlit> {<http://ns.ausnc.org.au/corpora/austlit/items/adaessa.xml> <http://purl.org/dc/terms/isPartOf> ?o}}} |
#    Then I should get a 200 response code
#    And the JSON response should be:
#    """
#    {
#      "head":{
#        "vars":[
#          "o"
#        ]
#      },
#      "results":{
#        "bindings":[
#          {
#            "o":{
#              "type":"uri",
#              "value":"http://ns.ausnc.org.au/corpora/cooee"
#            }
#          },
#          {
#            "o":{
#              "type":"uri",
#              "value":"http://ns.ausnc.org.au/corpora/austlit"
#            }
#          }
#        ]
#      }
#    }
#    """

#  Scenario: Send sparql query to retrieve an item identifier by specifying collection and also using wrong Service with Silent keyword
#    Given I ingest "cooee:1-001" with id "hcsvlab:1"
#    Given I have user "researcher1@intersect.org.au" with the following groups
#      | collectionName  | accessType  |
#      | cooee           | read        |
#    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
#      | query                                                                                                                                                                          |
#      | SELECT ?o {{<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/isPartOf> ?o} UNION {SERVICE SILENT <http://localhost:8984/openrdf-sesame/repositories/notexists> {?s ?p ?o}}} |
#    Then I should get a 200 response code
#    And the JSON response should be:
#    """
#    {
#      "head":{
#        "vars":[
#          "o"
#        ]
#      },
#      "results":{
#        "bindings":[
#          {
#            "o":{
#              "type":"uri",
#              "value":"http://ns.ausnc.org.au/corpora/cooee"
#            }
#          },
#          {
#            "1":{}
#          }
#        ]
#      }
#    }
#    """
