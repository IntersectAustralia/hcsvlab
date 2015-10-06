Feature: Browsing via API
  As a Researcher,
  I want to use the API to get metadata relating to a particular Item.

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
    Given I ingest "cooee:1-001"
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
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                              | text                                                     |
      | $..['dc:created']                      | 10/11/1791                                               |
      | $..['dc:identifier']                   | 1-001                                                    |
      | $..['dc:isPartOf']                     | cooee                                                    |
      | $..['dc:type']                         | Text, Original, Raw                                      |
      | $..['ausnc:itemwordcount']             | 924                                                      |
      | $..['ausnc:discourse_type']            | letter                                                   |
      | $..['olac:language']                   | eng                                                      |
      | $..['olac:speaker']                    | 1-001addressee, 1-001author                              |
      | $..['cooee:register']                  | Private Written                                          |
      | $..['cooee:texttype']                  | Private Correspondence                                   |
      | $..['bibo:pages']                      | 10-11                                                    |
      | $..["alveo:sparqlEndpoint"]            | http://example.org/sparql/cooee                          |
      | $..["alveo:annotations_url"]           | http://example.org/catalog/cooee/1-001/annotations.json  |
      | $..["alveo:primary_text_url"]          | http://example.org/catalog/cooee/1-001/primary_text.json |
      | $..["alveo:documents"][0]["dc:extent"] | 4960                                                     |
      | $..["alveo:documents"][2]["dc:title"]  | 1-001#Raw                                                |

  Scenario: Get item details for austalk item
    Given I ingest "austalk:1_1014_1_11_001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | austalk        | read       |
    When I make a JSON request for the catalog page for "austalk:1_1014_1_11_001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                                                     | text                                |
      | $..['dc:created']                                             | Fri Sep 09 14:18:48 2011            |
      | $..['dc:identifier']                                          | 1_1014_1_11_001                     |
      | $..['dc:isPartOf']                                            | 1_1014_1_11                         |
      | $..['dc:type']                                                | Audio                               |
      | $..['olac:speaker']                                           | 1_1014                              |
      | $..['austalk:component']                                      | 11                                  |
      | $..['austalk:componentName']                                  | calibration                         |
      | $..['austalk:prompt']                                         | Turn right 90  (face right wall)  2 |
      | $..['austalk:prototype']                                      | 11_1                                |
      | $..['austalk:session']                                        | 1                                   |
      | $..['austalk:version']                                        | 1.6                                 |
      | $..["alveo:sparqlEndpoint"]                                   | http://example.org/sparql/austalk   |
      | $..["alveo:primary_text_url"]                                 | No primary text found               |
      | $..["alveo:documents"][0]["http://ns.austalk.edu.au/channel"] | ch6-speaker16                       |
      | $..["alveo:documents"][0]["http://ns.austalk.edu.au/version"] | 1                                   |
    And the JSON response should not have
      | json_path                    | text                                                                |
      | $..["alveo:annotations_url'] | http://example.org/catalog/austalk/1_1014_1_11_001/annotations.json |

  Scenario: Get item details should not return fields used for authorization
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
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
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog page for "cooee:something" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download primary_text from item
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog primary text page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then I should get the primary text for "cooee:1-001"

  Scenario: Download primary_text from item with UTF-8 Characters
    Given I ingest "custom:utf8_test_1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | custom         | read       |
    When I make a JSON request for the catalog primary text page for "custom:utf8_test_1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the response should be:
    """
    This is a file that test this utf-8 characters:

    Ȇ	LATIN CAPITAL LETTER E WITH INVERTED BREVE (U+0206)
    Ȓ	LATIN CAPITAL LETTER R WITH INVERTED BREVE (U+0212)
    ʯ	LATIN SMALL LETTER TURNED H WITH FISHHOOK AND TAIL (U+02AF)
    Ώ	GREEK CAPITAL LETTER OMEGA WITH TONOS (U+038F)
    θ	GREEK SMALL LETTER THETA (U+03B8)
    ժ	ARMENIAN SMALL LETTER ZHE (U+056A)
    ק	HEBREW LETTER QOF (U+05E7)
    ؽ	ARABIC LETTER FARSI YEH WITH INVERTED V (U+063D)
    ल	DEVANAGARI LETTER LA (U+0932)
    """

  Scenario: Download primary_text from item that doesn't exist
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog primary text page for "hcsvlab:666" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download document which exists
    Given I ingest "cooee:1-002"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "cooee:1-002" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the response should be:
    """
    This is the plain text file 1-002-plain.txt.

    """

  Scenario: Download document that doesn't exist for item that does exist
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the document content page for file "blah.txt" for item "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Download document where the item doesn't exist
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the document content page for file "blah.txt" for item "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code
    Then the JSON response should be:
    """
    {"error":"not-found"}
    """

  Scenario: Access collection details via the API
    Given I ingest "cooee:1-001"
    And I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
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
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a request with no accept header for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have
      | json_path                     | text                                                     |
      | $..["alveo:annotations_url"]  | http://example.org/catalog/cooee/1-001/annotations.json  |
      | $..["alveo:primary_text_url"] | http://example.org/catalog/cooee/1-001/primary_text.json |

  Scenario: Search for simple term in all metadata
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I ingest "ice:S2B-035"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | auslit         | read       |
      | ice            | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata  |
      | monologue |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/ice/S2B-035"]}
    """

  Scenario: Search for two simple term in all metadata joined with AND via the API
    Given I ingest "cooee:1-001"
    Given I ingest "ice:S2B-035"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
      | ice            | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata               |
      | University AND Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/austlit/bolroma"]}
    """

  Scenario: Search for two simple term in all metadata joined with OR via the API
    Given I ingest "cooee:1-001"
    Given I ingest "ice:S2B-035"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
      | ice            | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata              |
      | University OR Romance |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/austlit/adaessa","http://example.org/catalog/austlit/bolroma"]}
    """

  Scenario: Search for term with asterisk in all metadata via the API
    Given I ingest "cooee:1-001"
    Given I ingest "cooee:1-002"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata   |
      | Correspon* |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/1-002"]}
    """

  Scenario: Search metadata with field:value via the API using solr field name
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                          |
      | AUSNC_discourse_type_tesim:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata              |
      | discourse_type:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name and all metadata search
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                                 |
      | Correspondence AND discourse_type:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with field:value via the API using user friendly field name and all metadata search with asterisk
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                             |
      | Correspon* AND discourse_type:letter |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/cooee/1-001"]}
    """

  Scenario: Search metadata with quotes via the API
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata                       |
      | date_group_facet:"1880 - 1889" |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":1,"items":["http://example.org/catalog/austlit/adaessa"]}
    """

  Scenario: Search metadata with ranges via the API
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
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
    Given I ingest "cooee:1-001"
    Given I ingest "ice:S2B-035"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | ice            | read       |
    Given I make a JSON request for the catalog search page with the API token for "researcher1@intersect.org.au" with params
      | metadata |
      | eng      |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"num_results":2,"items":["http://example.org/catalog/cooee/1-001", "http://example.org/catalog/ice/S2B-035"]}
    """

  Scenario: Add items to a new item list via the API
    Given I ingest "cooee:1-001"
    Given I ingest "cooee:1-002"
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
    Given I ingest "cooee:1-002"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                      |
      | cooee | ["http://example.org/catalog/cooee/1-002"] |
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
    Given I ingest "cooee:1-001"
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                                                                    |
      | cooee | ["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/non-exists"] |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"1 items added to new item list cooee"}
    """

  Scenario: Add items to an item list via the API sending in items as string
    Given I make a JSON post request for the item lists page with the API token for "researcher1@intersect.org.au" with JSON params
      | name  | items                                  |
      | cooee | http://example.org/catalog/hcsvlab/any |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"items parameter not an array"}
    """

  Scenario: Rename an item list via the API
    Given "researcher1@intersect.org.au" has item lists
      | name        |
      | Rename Test |
    And I make a JSON put request for the item list page for "Rename Test" with the API token for "researcher1@intersect.org.au" with JSON params
      | name     |
      | New Name |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"name":"New Name","num_items":0,"items":[]}
    """

  Scenario: Rename an item list via the API with invalid name
    Given "researcher1@intersect.org.au" has item lists
      | name        |
      | Rename Test |
    And I make a JSON put request for the item list page for "Rename Test" with the API token for "researcher1@intersect.org.au" with JSON params
      | name                                                                                                                                                                                                                                                                |
      | Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name Long name |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name too long"}
    """

  Scenario: Download items metadata and files in Zip format including non-existent items
    Given I ingest "cooee:1-001"
    Given I make a JSON post request for the download_items page with the API token for "researcher1@intersect.org.au" with JSON params
      | format | items                                                                                    |
      | zip    | ["http://example.org/catalog/cooee/1-001","http://example.org/catalog/cooee/non-exists"] |
    Then I should get a 200 response code

  Scenario: Download items metadata and files in Warc format
    Given I ingest "cooee:1-001"
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
    Given I ingest "cooee:1-001"
    And "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the annotation context page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":{"commonProperties":{"@id":"http://purl.org/dada/schema/0.2#commonProperties"},"dada":{"@id":"http://purl.org/dada/schema/0.2#"},"type":{"@id":"http://purl.org/dada/schema/0.2#type"},"start":{"@id":"http://purl.org/dada/schema/0.2#start"},"end":{"@id":"http://purl.org/dada/schema/0.2#end"},"label":{"@id":"http://purl.org/dada/schema/0.2#label"},"alveo":{"@id":"http://alveo.edu.au/schema/"},"ace":{"@id":"http://ns.ausnc.org.au/schemas/ace/"},"ausnc":{"@id":"http://ns.ausnc.org.au/schemas/ausnc_md_model/"},"austalk":{"@id":"http://ns.austalk.edu.au/"},"austlit":{"@id":"http://ns.ausnc.org.au/schemas/austlit/"},"bibo":{"@id":"http://purl.org/ontology/bibo/"},"cooee":{"@id":"http://ns.ausnc.org.au/schemas/cooee/"},"dc":{"@id":"http://purl.org/dc/terms/"},"foaf":{"@id":"http://xmlns.com/foaf/0.1/"},"gcsause":{"@id":"http://ns.ausnc.org.au/schemas/gcsause/"},"ice":{"@id":"http://ns.ausnc.org.au/schemas/ice/"},"olac":{"@id":"http://www.language-archives.org/OLAC/1.1/"},"purl":{"@id":"http://purl.org/"},"rdf":{"@id":"http://www.w3.org/1999/02/22-rdf-syntax-ns#"},"schema":{"@id":"http://schema.org/"},"xsd":{"@id":"http://www.w3.org/2001/XMLSchema#"}}}
    """

  Scenario: Get annotation context without API token
    Given I make a JSON request for the annotation context page without an API token
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"@context":{"commonProperties":{"@id":"http://purl.org/dada/schema/0.2#commonProperties"},"dada":{"@id":"http://purl.org/dada/schema/0.2#"},"type":{"@id":"http://purl.org/dada/schema/0.2#type"},"start":{"@id":"http://purl.org/dada/schema/0.2#start"},"end":{"@id":"http://purl.org/dada/schema/0.2#end"},"label":{"@id":"http://purl.org/dada/schema/0.2#label"},"alveo":{"@id":"http://alveo.edu.au/schema/"},"ace":{"@id":"http://ns.ausnc.org.au/schemas/ace/"},"ausnc":{"@id":"http://ns.ausnc.org.au/schemas/ausnc_md_model/"},"austalk":{"@id":"http://ns.austalk.edu.au/"},"austlit":{"@id":"http://ns.ausnc.org.au/schemas/austlit/"},"bibo":{"@id":"http://purl.org/ontology/bibo/"},"cooee":{"@id":"http://ns.ausnc.org.au/schemas/cooee/"},"dc":{"@id":"http://purl.org/dc/terms/"},"foaf":{"@id":"http://xmlns.com/foaf/0.1/"},"gcsause":{"@id":"http://ns.ausnc.org.au/schemas/gcsause/"},"ice":{"@id":"http://ns.ausnc.org.au/schemas/ice/"},"olac":{"@id":"http://www.language-archives.org/OLAC/1.1/"},"purl":{"@id":"http://purl.org/"},"rdf":{"@id":"http://www.w3.org/1999/02/22-rdf-syntax-ns#"},"schema":{"@id":"http://schema.org/"},"xsd":{"@id":"http://www.w3.org/2001/XMLSchema#"}}}
    """

  Scenario: Get annotations for item
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {"@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "alveo:annotates":"http://example.org/catalog/cooee/1-001/document/1-001-plain.txt"
      },
      "alveo:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/0",
          "label":"11",
          "type":"pageno",
          "@type":"dada:TextAnnotation",
          "end":"2460",
          "start":"2460"
        },
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type":"ellipsis",
          "@type":"dada:TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item with different @type
    Given I ingest "cooee:1-002"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-002" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "alveo:annotates":"http://example.org/catalog/cooee/1-002/document/1-002-plain.txt"
      },
      "alveo:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-002/0",
          "label":"ai",
          "type":"phonetic",
          "@type":"dada:SecondAnnotation",
          "end":"1.1548",
          "start":"1.1348"
        }
      ]
    }
    """

  Scenario: Request annotations for item that doesn't have annotations
    Given I ingest "auslit:adaessa"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotations page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations for item that doesn't exist
    Given I ingest "cooee:1-001"
    When I make a JSON request for the catalog annotations page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotation properties for an item
    Given I ingest "cooee:1-002"
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
          "uri": "http://purl.org/dada/schema/0.2#label",
          "shortened_uri": "dada:label"
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
    Given I ingest "auslit:adaessa"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotation properties page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations properties for item that doesn't exist
    Given I ingest "cooee:1-001"
    When I make a JSON request for the catalog annotation properties page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotation types for an item
    Given I ingest "cooee:1-002"
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
    Given I ingest "auslit:adaessa"
    Given "researcher1@intersect.org.au" has "read" access to collection "austlit"
    When I make a JSON request for the catalog annotation types page for "auslit:adaessa" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get annotations types for item that doesn't exist
    Given I ingest "cooee:1-001"
    When I make a JSON request for the catalog annotation types page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au"
    Then I should get a 404 response code

  Scenario: Get specific annotations for item by label
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | label |
      | 11    |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "alveo:annotates":"http://example.org/catalog/cooee/1-001/document/1-001-plain.txt"
      },
      "alveo:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/0",
          "label":"11",
          "type":"pageno",
          "@type":"dada:TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get specific annotations for item by type
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | type     |
      | ellipsis |
    Then I should get a 200 response code
    Then the JSON response should be:
    """
    {
      "@context":"http://example.org/schema/json-ld",
      "commonProperties":{
        "alveo:annotates":"http://example.org/catalog/cooee/1-001/document/1-001-plain.txt"
      },
      "alveo:annotations":[
        {
          "@id":"http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type":"ellipsis",
          "@type":"dada:TextAnnotation",
          "end":"2460",
          "start":"2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item using extra properties
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | dada:start | dada:targets                                             |
      | 2460       | http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1L |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "@context": "http://example.org/schema/json-ld",
      "commonProperties": {
        "alveo:annotates": "http://example.org/catalog/cooee/1-001/document/1-001-plain.txt"
      },
      "alveo:annotations": [
        {
          "@id": "http://ns.ausnc.org.au/corpora/cooee/annotation/1-001/1",
          "type": "ellipsis",
          "@type": "dada:TextAnnotation",
          "end": "2460",
          "start": "2460"
        }
      ]
    }
    """

  Scenario: Get annotations for item using invalid property
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with params
      | property |
      | test     |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"error in query parameters"}
    """

  Scenario: Get annotations for item including a user uploaded one
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 200 response code
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should have 5 user uploaded annotations
    And the JSON response should have the following annotations properties in any order:
      | label | type     | @type               | end  | start |
      | 11    | pageno   | dada:TextAnnotation | 2460 | 2460  |
      |       | ellipsis | dada:TextAnnotation | 2460 | 2460  |
      | 449   | pageno   | dada:TextAnnotation | 421  | 421   |
      | ...   | pageno   | dada:TextAnnotation | 2524 | 2524  |
      | 451   | pageno   | dada:TextAnnotation | 6309 | 6309  |
      | ...   | pageno   | dada:TextAnnotation | 6598 | 6598  |
      | 450   | pageno   | dada:TextAnnotation | 3475 | 3475  |


  ###########################################################################################################
  #### UPLOAD ANNOTATIONS TESTS                                                                          ####
  ###########################################################################################################

  Scenario: Successfully uploaded user annotation
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 200 response code

  Scenario: Upload annotation to non existing item
    Given I ingest "cooee:1-001"
    When I make a JSON multipart request for the catalog annotations page for "cooee:non-exists" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 404 response code

  Scenario: Upload blank annotation to an item
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                                     | Type                     |
      | file |         | test/samples/annotations/blank_upload_annotation_sample.json | application/octet-stream |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Uploaded file is not present or empty."}
    """

  Scenario: Upload same annotation file twice
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 200 response code

    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"File already uploaded."}
    """

  Scenario: Upload malformed annotation to an item
    Given I ingest "cooee:1-001"
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                                         | Type                     |
      | file |         | test/samples/annotations/malformed_upload_annotation_sample.json | application/octet-stream |
    Then I should get a 500 response code
    And the JSON response should be:
    """
    {"error":"Error uploading file malformed_upload_annotation_sample.json."}
    """

  Scenario: Uploaded user annotation for an item I have no read access
    Given I ingest "cooee:1-001"
    When I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    Then I should get a 403 response code

  ###########################################################################################################
  #### SPARQL ENDPOINT TESTS                                                                             ####
  ###########################################################################################################

  Scenario: Send sparql query without specifying the query.
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query |
      |       |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Parameter 'query' is required."}
    """

  Scenario: Send sparql query to a collection I have no access.
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog sparql page for collection "austlit" with the API token for "researcher1@intersect.org.au" with params
      | query                     |
      | select * where {?s ?p ?o} |
    Then I should get a 403 response code


#
# In the near future we might allow the SERVICE keyword in the query. I'll leave this test for that purpose
#
#  Scenario: Send sparql query to a collection I have no access by using the service keyword.
#    Given I ingest "cooee:1-001"
#    Given I ingest "auslit:adaessa"
#    Given I have user "researcher1@intersect.org.au" with the following groups
#      | collectionName  | accessType  |
#      | cooee           | read        |
#    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
#      | query                                                                                                                            |
#      | select * where {SERVICE <http://localhost:8984/openrdf-sesame/repositories/austlit> {?s <http://purl.org/dc/terms/isPartOf> ?o}} |
#    Then I should get a 403 response code


  Scenario: Send sparql query to a collection that does not exists.
    When I make a JSON request for the catalog sparql page for collection "notExists" with the API token for "researcher1@intersect.org.au" with params
      | query                     |
      | select * where {?s ?p ?o} |
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"collection not-found"}
    """

  Scenario: Send sparql query to retrieve an item identifier
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
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
#    Given I ingest "cooee:1-001"
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
    Given I ingest "cooee:1-001"
    Given I ingest "cooee:1-002"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
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
    Given I ingest "cooee:1-001"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I make a JSON request for the catalog sparql page for collection "cooee" with the API token for "researcher1@intersect.org.au" with params
      | query                                                                                                                                                                                                   |
      | SELECT ?o {{<http://ns.ausnc.org.au/corpora/cooee/items/1-001> <http://purl.org/dc/terms/isPartOf> ?o} UNION {SERVICE SILENT <http://localhost:8984/openrdf-sesame/repositories/notexists> {?s ?p ?o}}} |
    Then I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Service keyword is forbidden in queries."}
    """

  Scenario: Send sparql query to retrieve utf-8 text in Russian
    Given I ingest "custom:custom1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | custom         | read       |
    When I make a JSON request for the catalog sparql page for collection "custom" with the API token for "researcher1@intersect.org.au" with params
      | query                                                                                                                                  |
      | select * where {<http://ns.ausnc.org.au/corpora/austlit/items/custom1.xml> <http://ns.ausnc.org.au/schemas/ausnc_md_model/russian> ?o} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "head":{
        "vars":["o"]
      },
      "results":{
        "bindings":[
          {
            "o":{
              "type": "literal",
              "value":"котята"
            }
          }
        ]
      }
    }
    """

  Scenario: Send sparql query to retrieve utf-8 text in Chinese
    Given I ingest "custom:custom1"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName | accessType |
      | custom         | read       |
    When I make a JSON request for the catalog sparql page for collection "custom" with the API token for "researcher1@intersect.org.au" with params
      | query                                                                                                                                  |
      | select * where {<http://ns.ausnc.org.au/corpora/austlit/items/custom1.xml> <http://ns.ausnc.org.au/schemas/ausnc_md_model/chinese> ?o} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "head":{
        "vars":["o"]
      },
      "results":{
        "bindings":[
          {
            "o":{
              "type": "literal",
              "value":"双喜/雙喜 shuāngxǐ"
            }
          }
        ]
      }
    }
    """

#
# In the near future we might allow the SERVICE keyword in the query. I'll leave these 2 tests for that purpose
#
#  Scenario: Send sparql query to retrieve an item identifier by specifying collection and also using Service keyword
#    Given I ingest "cooee:1-001"
#    Given I ingest "auslit:adaessa"
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
#    Given I ingest "cooee:1-001"
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

  Scenario: Use API to get collections list
    Given I ingest "cooee:1-001"
    Given I ingest "ice:S2B-035"
    Given I ingest "auslit:adaessa"
    Given I make a JSON request for the collections page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "num_collections": 3,
      "collections":[
        "http://example.org/catalog/austlit",
        "http://example.org/catalog/cooee",
        "http://example.org/catalog/ice"
      ]
    }
    """

  Scenario: Use API to get collections list, no collections
    Given I make a JSON request for the collections page with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {
      "num_collections": 0,
      "collections":[]
    }
    """

  Scenario: Use API to delete an item list
    Given I make a JSON delete request for the item list page for "Test 1" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"item list Test 1 deleted successfully"}
    """

  Scenario: Share item_list via the API
    Given I make a JSON post request for the share item list page for "Test 1" with the API token for "researcher1@intersect.org.au" without JSON params
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Item list Test 1 is shared. Any user in the application will be able to see it."}
    """

  Scenario: Unshare item_list via the API
    Given I make a JSON post request for the unshare item list page for "Test 1" with the API token for "researcher1@intersect.org.au" without JSON params
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Item list Test 1 is not being shared anymore."}
    """

  Scenario: Clear item_list via the API, more than one items
    Given I ingest "cooee:1-001"
    And I ingest "cooee:1-002"
    And "researcher1@intersect.org.au" has item lists
      | name       |
      | Clear Test |
    And the item list "Clear Test" has items cooee:1-001, cooee:1-002
    When I make a JSON post request for the clear item list page for "Clear Test" with the API token for "researcher1@intersect.org.au" without JSON params
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"2 cleared from item list Clear Test"}
    """

  Scenario: Clear item_list via the API, only one item
    Given I ingest "cooee:1-001"
    And "researcher1@intersect.org.au" has item lists
      | name       |
      | Clear Test |
    And the item list "Clear Test" has items cooee:1-001
    When I make a JSON post request for the clear item list page for "Clear Test" with the API token for "researcher1@intersect.org.au" without JSON params
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"1 cleared from item list Clear Test"}
    """

  Scenario: Clear item_list via the API, no item at all
    When I make a JSON post request for the clear item list page for "Test 1" with the API token for "researcher1@intersect.org.au" without JSON params
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"0 cleared from item list Test 1"}
    """

  @api_create_collection
  Scenario: Create new collection via the API as a researcher
    Given I make a JSON post request for the collections page with the API token for "researcher1@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"Permission Denied: Your role within the system does not have sufficient privileges to be able to create a collection. Please contact an Alveo administrator."}
    """

  @api_create_collection
  Scenario: Create new collection via the API as a data owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://collection.test) created"}
    """

  @api_create_collection
  Scenario: Create new collection via the API as an admin
    Given I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://collection.test) created"}
    """

  @api_create_collection
  Scenario: Create new collection via the API with duplicate name
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://other.collection/test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://other.collection/test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "Another test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://other.collection/test) created"}
    """

  @api_create_collection
  Scenario: Create new collection via the API with duplicate uri
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name         | collection_metadata |
      | Another Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "Another test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Collection 'Another Test' (http://collection.test) already exists in the system - skipping"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without JSON params
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" without JSON params
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name and metadata parameters not found"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without name param
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | collection_metadata |
      | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"name parameter not found"}
    """

  @api_create_collection
  Scenario: Create new collection via the API without the metadata param
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
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
    Given I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the owner of collection "Test" should be "admin@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://collection.test) created"}
    """

  @api_create_collection
  Scenario: Create new collection assigns collection owner to api key user who is also the default collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    Then I should get a 200 response code
    And the owner of collection "Test" should be "data_owner@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://collection.test) created"}
    """

  @api_create_collection
  Scenario: Create new collection assigns collection owner to api key user even if they specify an owner in the metadata
    # assign the collection owner to be "researcher1@intersect.org.au" in the collection metadata (using the marcel:rpy tag)
    Given I make a JSON post request for the collections page with the API token for "admin@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"TEST": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:rpy": "researcher1@intersect.org.au"} |
    Then I should get a 200 response code
    And the owner of collection "Test" should be "admin@intersect.org.au"
    And the JSON response should be:
    """
    {"success":"New collection 'Test' (http://collection.test) created"}
    """

  @api_add_item
  Scenario: Add items to non-existing collection
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "NonExistantItem" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested collection not found"}
    """

  @api_add_item
  Scenario: Add an item without item metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ ] |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"JSON-LD formatted item metadata must be sent with the api request"}
    """

  @api_add_item
  Scenario: Add items to another users collection
    Given I have users
      | email                        | first_name | last_name |
      | data_owner2@intersect.org.au | Data_Owner | Two       |
    And "data_owner2@intersect.org.au" has role "data owner"
    And "data_owner2@intersect.org.au" has an api token
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner2@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    Then I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"User is unauthorised"}
    """

  @api_add_item
  Scenario: Add an item with ill-formatted JSON
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | } [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"JSON item metadata is ill-formatted"}
    """

  @api_add_item
  Scenario: Add one item to my collection
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item which already exists in my collection
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The item item1 already exists in the collection Test"}
    """

  @api_add_item
  Scenario: Add many items to my collection
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      # ToDo: fix rpec post request merging hashes in array, see: http://stackoverflow.com/questions/18337609/rspec-request-test-merges-hashes-in-array-in-post-json-params
#      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } }, { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document2.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document2.txt" }, "hcsvlab:display_document": { "@id": "document2.txt" } } ] } } ] |
      | [ { "dummy": "value1", "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } }, { "dummy": "value2", "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document2.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document2.txt" }, "hcsvlab:display_document": { "@id": "document2.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And the file "item2-metadata.rdf" should exist in the directory for the collection "Test"
    And the item "item2" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item2" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1", "item2"]}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "document1.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "document1.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/document1.txt" in collection "Test"
    And Sesame should contain a document with file_name "document1.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON missing the document name
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"identifier missing from document"}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON missing the document content
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"content missing from document document1.txt"}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON when that document identifier already exists as a file
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item2", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "document1.txt" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The file \"document1.txt\" has already been uploaded to the collection Test"}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON with multiple identical document identifiers within one item
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content":"This is a doc." }, { "identifier": "document1.txt", "content":"This is the same doc again!" } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The identifier \"document1.txt\" is used for multiple documents"}
    """

  @api_add_item
  Scenario: Add an item with a document as JSON with multiple identical document identifiers across multiple items
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This is a doc." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } }, { "documents": [ { "identifier": "document1.txt", "content": "This is the same doc again!." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file://uploaded/file.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The identifier \"document1.txt\" is used for multiple documents"}
    """

  @api_add_item @test
  Scenario: Add an item with a single document file as a multipart http request
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "1-001-plain.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-001-plain.txt" in collection "Test"
    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  # ToDo: fix rpec post request merging hashes (document hashes) in array, see: http://stackoverflow.com/questions/18337609/rspec-request-test-merges-hashes-in-array-in-post-json-params
#  @api_add_item @test
#  Scenario: Add an item with many document files as a multipart http request
#    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
#      | name | collection_metadata |
#      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
#    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
#      | file                                                                      | items |
#      | "test/samples/cooee/1-001-plain.txt","test/samples/cooee/1-002-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" }, { "@id": "1-002-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-002-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
##      | "test/samples/cooee/1-001-plain.txt","test/samples/cooee/1-002-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
#    Then the file "manifest.json" should exist in the directory for the collection "Test"
#    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
#    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
#    And the file "1-002-plain.txt" should exist in the directory for the collection "Test"
#    And the item "item1" in collection "Test" should exist in the database
#    And the document "1-001-plain.txt" in collection "Test" should exist in the database
#    And the document "1-002-plain.txt" in collection "Test" should exist in the database
#    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
#    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-001-plain.txt" in collection "Test"
#    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-002-plain.txt" in collection "Test"
#    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "Test"
#    And Sesame should contain a document with file_name "1-002-plain.txt" in collection "Test"
#    And I should get a 200 response code
#    And the JSON response should be:
#    """
#    {"success":["item1"]}
#    """

  # ToDo: remove following workaround test once previous api_steps are fixed so that the previous test passes
  @api_add_item @test
  Scenario: Add an item with many document files as a multipart http request
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                                                      | items |
      | "test/samples/cooee/1-001-plain.txt","test/samples/cooee/1-002-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
    And the file "1-002-plain.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "1-001-plain.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-001-plain.txt" in collection "Test"
    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item with an ill-formatted file parameter as a multipart http request
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and ill-formatted file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"1-001-plain.txt", "dcterms:source":{ "@id":"file://foo.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Error in file parameter."}
    """

  @api_add_item
  Scenario: Add an item with an empty file as a multipart http request
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                         | items |
      | "test/samples/api/blank.txt" | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"1-001-plain.txt", "dcterms:source":{ "@id":"file://foo.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"Uploaded file \"blank.txt\" is not present or empty."}
    """

  @api_add_item
  Scenario: Add an item with an existing document file as a multipart http request
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"1-001-plain.txt", "dcterms:source":{ "@id":"file://foo.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    And I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"1-001-plain.txt", "dcterms:source":{ "@id":"file://foo.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item2", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The file \"1-001-plain.txt\" has already been uploaded to the collection Test"}
    """

  @api_add_item
  Scenario: Add an item with a uploaded filename identical to a document identifier
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "documents": [ { "identifier": "1-001-plain.txt", "content":"This is a doc." } ], "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"1-001-plain.txt", "dcterms:source":{ "@id":"file://foo.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 412 response code
    And the JSON response should be:
    """
    {"error":"The identifier \"1-001-plain.txt\" is used for multiple documents"}
    """

  @api_add_item
  Scenario: Add an item with invalid RDF should fail
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    # The invalid RDF of the following add item JSON-LD metadata is that there is a space in the corpus part of "dcterms:isPartOf":{ "@id":"corpus: Test" }
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus: Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should not exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"No items were added", "failures":["Unknown item contains invalid metadata"]}
    """

  @api_add_item
  Scenario: Add many items should fail if all items have invalid metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    # The invalid RDF of the item1 and item2 JSON-LD metadata is that there is a space in the corpus part of "dcterms:isPartOf":{ "@id":"corpus: Test" }
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      # ToDo: fix rpec post request merging hashes in array, see: http://stackoverflow.com/questions/18337609/rspec-request-test-merges-hashes-in-array-in-post-json-params
      | [ {"dummy":"value1", "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus: Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } }, {"dummy":"value2", "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document2-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title":"document2#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item2", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document2#Text" } ], "dcterms:identifier":"item2", "dcterms:isPartOf":{ "@id":"corpus: Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document2#Text" } } ] } } ] |
#      | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus: Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } }, { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document2-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title":"document2#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item2", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document2#Text" } ], "dcterms:identifier":"item2", "dcterms:isPartOf":{ "@id":"corpus: Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document2#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should not exist in the directory for the collection "Test"
    And the file "item2-metadata.rdf" should not exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"No items were added", "failures":["Unknown item contains invalid metadata", "Unknown item contains invalid metadata"]}
    """

  @api_add_item
  Scenario: Add many items should succeed if some items have invalid metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    # The invalid RDF of the item1 JSON-LD metadata is that there is a space in the corpus part of "dcterms:isPartOf":{ "@id":"corpus: Test" }
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      # ToDo: fix rpec post request merging hashes in array, see: http://stackoverflow.com/questions/18337609/rspec-request-test-merges-hashes-in-array-in-post-json-params
      | [ { "dummy": "value2", "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "http://ns.ausnc.org.au/corpora/art/items/item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1-plain.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus: Test" }, "hcsvlab:display_document": { "@id": "http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } }, { "dummy": "value2", "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "http://ns.ausnc.org.au/corpora/art/items/item2", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document2-plain.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "http://ns.ausnc.org.au/corpora/source/document2#Text" } } ] } } ] |
#      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "http://ns.ausnc.org.au/corpora/art/items/item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1-plain.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus: Test" }, "hcsvlab:display_document": { "@id": "http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } }, { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "http://ns.ausnc.org.au/corpora/art/items/item2", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document2-plain.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document1.txt" }, "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "http://ns.ausnc.org.au/corpora/source/document2#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should not exist in the directory for the collection "Test"
    And the file "item2-metadata.rdf" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item2"], "failures":["Unknown item contains invalid metadata"]}
    """

  @api_add_item
  Scenario: Add an item with a blank identifier
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"There is an item with a missing or blank identifier"}
    """

  @api_add_item
  Scenario: Add an item with whitespace as its identifier
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/", "hcsvlab":"http://hcsvlab.org/vocabulary/", "rdf":"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs":"http://www.w3.org/2000/01/rdf-schema#", "xsd":"http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:extent":72636, "dcterms:identifier":"document1-plain.txt", "dcterms:source":{ "@id":"file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"   ", "dcterms:isPartOf":{ "@id":"corpus:Test" }, "hcsvlab:display_document":{ "@id":"http://ns.ausnc.org.au/corpora/source/document1#Text" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"There is an item with a missing or blank identifier"}
    """
    
  @api_add_item
  Scenario: Add an item with nested (referenced) documents and shortened @ids
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1", "@type": "foaf:Document", "dcterms:extent": 1234, "dcterms:identifier": "document1.txt", "dcterms:source": { "@id": "file:///data/test_collections/ausnc/test/document2.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:indexable_document": { "@id": "document1.txt" }, "hcsvlab:display_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/document1.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item with nested (doc content in JSON) documents and shortened @ids
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "document1.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "document1.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/document1.txt" in collection "Test"
    And Sesame should contain a document with file_name "document1.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item without specifying the IS_PART_OF corpus metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "document1.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "document1.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/document1.txt" in collection "Test"
    And Sesame should contain a document with file_name "document1.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item with nested (multipart uploaded) documents and shortened @ids
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:source": { "@id": "file://foo.txt" }, "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "dcterms:isPartOf": { "@id": "corpus:Test" }, "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "1-001-plain.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-001-plain.txt" in collection "Test"
    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_add_item
  Scenario: Add an item with nested (multipart uploaded) documents, without specifing the is_part_of corpus or the document source
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON multipart request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON and file params
      | file                                 | items |
      | "test/samples/cooee/1-001-plain.txt" | [ { "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "1-001-plain.txt", "@type": "foaf:Document", "dcterms:extent": 72636, "dcterms:identifier": "1-001-plain.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "1-001-plain.txt" }, "hcsvlab:indexable_document": { "@id": "1-001-plain.txt" } } ] } } ] |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "1-001-plain.txt" should exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should exist in the database
    And the document "1-001-plain.txt" in collection "Test" should exist in the database
    And Sesame should contain an item with uri "http://example.org/catalog/Test/item1" in collection "Test"
    And Sesame should contain a document with uri "http://example.org/catalog/Test/item1/document/1-001-plain.txt" in collection "Test"
    And Sesame should contain a document with file_name "1-001-plain.txt" in collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":["item1"]}
    """

  @api_delete_item
  Scenario: Delete an item from a non-existing collection
    When I make a JSON delete request for the delete item "item1" from collection "Test" page with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested collection not found"}
    """

  @api_delete_item
  Scenario: Delete a non-existing item from a collection
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    When I make a JSON delete request for the delete item "item1" from collection "Test" page with the API token for "data_owner@intersect.org.au"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested item not found"}
    """

  @api_delete_item
  Scenario: Delete an item as someone other than the collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1-plain.txt", "content":"Hello World." } ], "metadata": { "@context": { "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus":"http://ns.ausnc.org.au/corpora/", "dc":"http://purl.org/dc/terms/", "dcterms":"http://purl.org/dc/terms/", "foaf":"http://xmlns.com/foaf/0.1/" }, "@graph": [ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text", "@type":"foaf:Document", "dcterms:identifier":"document1-plain.txt", "dcterms:title":"document1#Text", "dcterms:type":"Text" }, { "@id":"http://ns.ausnc.org.au/corpora/art/items/item1", "@type":"ausnc:AusNCObject", "ausnc:document":[ { "@id":"http://ns.ausnc.org.au/corpora/test/source/document1#Text" } ], "dcterms:identifier":"item1", "dcterms:isPartOf":{ "@id":"corpus:Test" } } ] } } ] |
    When I make a JSON delete request for the delete item "item1" from collection "Test" page with the API token for "researcher1@intersect.org.au"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should exist in the directory for the collection "Test"
    And the file "document1-plain.txt" should exist in the directory for the collection "Test"
    And I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"User is unauthorised"}
    """

  @api_delete_item @javascript
  Scenario: Delete an item as the collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "Test"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the home page
    When I make a JSON delete request for the delete item "item1" from collection "Test" page with the API token for "data_owner@intersect.org.au"
    And I have done a search with collection "Test"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And the file "item1-metadata.rdf" should not exist in the directory for the collection "Test"
    And the file "document1-plain.txt" should not exist in the directory for the collection "Test"
    And the item "item1" in collection "Test" should not exist in the database
    And the document "document1-plain.txt" in collection "Test" should not exist in the database
    And Sesame should not contain an item with uri "http://ns.ausnc.org.au/corpora/art/items/item1" in collection "Test"
    And Sesame should not contain a document with file_name "document1-plain.txt" in collection "Test"
    # No identifiers should be in the blacklight results since the only collection item has been deleted
    And I should see "blacklight_results" table with
      | Identifier | Type(s) |
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Deleted the item item1 (and its documents) from collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should not see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should not see "Title: A test collection"
    And I should see "Owner: Data Owner"
    And I should see "Title: An updated test collection"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should not see "Creator: Pam Peters"
    And I should not see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: Updated Language"
    And I should see "Title: An updated test collection"
    And I should not see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
    And I should see "Creator: Pam Peters"
    And I should see "Rights: All rights reserved to Data Owner"
    And I should see "Subject: English Language"
    And I should see "Title: An updated test collection"
    And I should see "Owner: Data Owner"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated collection Test"}
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
    And I follow "Test"
    Then the file "Test.n3" should exist in the directory for the api collections
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
    {"success":"Updated collection Test"}
    """

  @api_update_item
  Scenario: Update an item without being the collection owner
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "researcher1@intersect.org.au" with JSON params
      | metadata |
      | {"http://purl.org/dc/elements/1.1/title": "An updated test item"} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"User is unauthorised"}
    """

  @api_update_item
  Scenario: Update an item with invalid metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"http://purl.org/dc/elements/1.1/ title": "An updated test item"} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Invalid metadata"}
    """

  @api_update_item
  Scenario: Update an item with no metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" without JSON params
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Invalid metadata"}
    """

  @api_update_item
  Scenario: Update an item with empty metadata
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 400 response code
    And the JSON response should be:
    """
    {"error":"Invalid metadata"}
    """

  @api_update_item
  Scenario: Update an item that doesn't exist
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test2:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"http://purl.org/dc/elements/1.1/title": "An updated test item"} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested collection not found"}
    """

  @api_update_item
  Scenario: Update an item that doesn't exist
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item2" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"http://purl.org/dc/elements/1.1/title": "An updated test item"} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 404 response code
    And the JSON response should be:
    """
    {"error":"Requested item not found"}
    """

  @api_update_item
  Scenario: Update an item
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | {"http://purl.org/dc/elements/1.1/title": "An updated test item"} |
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated item item1 in collection Test"}
    """

  @api_update_item
  Scenario: Update an item and view the changes
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "Test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | { "http://ns.ausnc.org.au/schemas/ausnc_md_model/mode":"An updated test mode" } |
    And I go to the catalog page for "Test:item1"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated item item1 in collection Test"}
    """
    And I should see "Item Details"
    And I should see "Identifier: item1"
    And I should see "Collection: Test"
    And I should see "Mode: An updated test mode"

  @api_update_item
  Scenario: Update an item with a context and view the changes
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "Test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | { "@context":{ "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/" }, "ausnc:speech_style":"An updated speech style" } |
    And I go to the catalog page for "Test:item1"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated item item1 in collection Test"}
    """
    And I should see "Item Details"
    And I should see "Identifier: item1"
    And I should see "Collection: Test"
    And I should see "Speech Style: An updated speech style"

  @api_update_item
  Scenario: Update an item with multiple fields and a context and view the changes
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "Test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | { "@context":{ "ausnc":"http://ns.ausnc.org.au/schemas/ausnc_md_model/" }, "ausnc:speech_style":"An updated speech style", "ausnc:mode":"An updated mode" } |
    And I go to the catalog page for "Test:item1"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated item item1 in collection Test"}
    """
    And I should see "Item Details"
    And I should see "Identifier: item1"
    And I should see "Collection: Test"
    And I should see "Speech Style: An updated speech style"
    And I should see "Mode: An updated mode"

  @api_update_item
  Scenario: Updating an item's dc:identifier should not result in any changes
    Given I make a JSON post request for the collections page with the API token for "data_owner@intersect.org.au" with JSON params
      | name | collection_metadata |
      | Test | {"@context": {"Test": "http://collection.test", "dc": "http://purl.org/dc/elements/1.1/", "dcmitype": "http://purl.org/dc/dcmitype/", "marcrel": "http://www.loc.gov/loc.terms/relators/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@id": "http://collection.test", "@type": "dcmitype:Collection", "dc:creator": "Pam Peters", "dc:rights": "All rights reserved to Data Owner", "dc:subject": "English Language", "dc:title": "A test collection", "marcrel:OWN": "Data Owner"} |
    And I make a JSON post request for the collection page for id "Test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "This document had its content provided as part of the JSON request." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/", "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdfs": "http://www.w3.org/2000/01/rdf-schema#", "xsd": "http://www.w3.org/2001/XMLSchema#" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "Test"
    And I am logged in as "data_owner@intersect.org.au"
    When I make a JSON put request for the update item page for "Test:item1" with the API token for "data_owner@intersect.org.au" with JSON params
      | metadata |
      | { "http://purl.org/dc/terms/identifier":"updated_id" } |
    And I go to the catalog page for "Test:item1"
    Then the file "manifest.json" should exist in the directory for the collection "Test"
    And I should get a 200 response code
    And the JSON response should be:
    """
    {"success":"Updated item item1 in collection Test"}
    """
    And I should see "Item Details"
    And I should see "Identifier: item1"
    And I should not see "Identifier: updated_id"

