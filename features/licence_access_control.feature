Feature: Collection access control
  As a Data Owner, I only want users that have agreed
  to the licence for my collection to see that collection.

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                        | first_name | last_name |
      | data_owner1@intersect.org.au | dataOwner1 | One       |
      | data_owner2@intersect.org.au | dataOwner2 | Two       |
      | researcher1@intersect.org.au | Researcher | R         |
    Given "data_owner1@intersect.org.au" has role "data owner"
    Given "data_owner2@intersect.org.au" has role "data owner"
    Given "researcher1@intersect.org.au" has role "researcher"
    Given "researcher1@intersect.org.au" has an api token
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given Collections ownership is
      | collection | owner_email                  |
      | austlit    | data_owner2@intersect.org.au |
      | cooee      | data_owner1@intersect.org.au |
    Given I ingest licences

  @javascript
  Scenario: Data Owner should be able to see all his collections
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      | collection |
      | austlit    |

  @javascript
  Scenario: Data Owner should be able to see all items of my collections
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier      | Type(s)             |
      | austlit:adaessa | Text, Original, Raw |
      | austlit:bolroma | Text, Original, Raw |

  @javascript
  Scenario: Data Owner should be able to see the details of his items
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the catalog page for "cooee:1-001"
    Then I should see "cooee:1-001"
    And I should see "Display Document"
    And I should see "Documents"

  @javascript
  Scenario: User should not be able to see the details of items he has no permission
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the catalog page for "austlit:adaessa"
    Then I should see "You do not have sufficient access privileges to read this document"

  @javascript
  Scenario: User should be able to see collections for which he has discover access
    Given "data_owner2@intersect.org.au" has "discover" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      | collection |
      | austlit    |
      | cooee      |

  @javascript
  Scenario: User should see every item in a collection for which he has discover access
    Given "data_owner1@intersect.org.au" has "discover" access to collection "austlit"
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier      | Type(s)             |
      | austlit:adaessa | Text, Original, Raw |
      | austlit:bolroma | Text, Original, Raw |

  @javascript
  Scenario: User should not be able to see details of items for which he has discover access
    Given "data_owner2@intersect.org.au" has "discover" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      | collection |
      | austlit    |
      | cooee      |
    Then I am on the catalog page for "cooee:1-001"
    And I should see "You do not have sufficient access privileges to read this document"

  @javascript
  Scenario: User should be able to see collections for which he has read access
    Given "data_owner2@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      | collection |
      | austlit    |
      | cooee      |

  @javascript
  Scenario: User should see every item in a collection for which he has read access
    Given "data_owner1@intersect.org.au" has "read" access to collection "austlit"
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier      | Type(s)             |
      | austlit:adaessa | Text, Original, Raw |
      | austlit:bolroma | Text, Original, Raw |

  @javascript
  Scenario: User should be able to see details of items for which he has read access
    Given "data_owner2@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      | collection |
      | austlit    |
      | cooee      |
    Then I am on the catalog page for "cooee:1-001"
    And I should see "cooee:1-001"
    And I should see "Display Document"
    And I should see "Documents"

#----------- No Access
  Scenario: Get item details for an item I have not access
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Get annotations for item I have not access
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Get primary text for item I have not access
    When I make a JSON request for the catalog primary text page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Download document which exists but I have not access
    When I make a JSON request for the document content page for file "1-001-plain.txt" for item "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Access collection details for which I have not access
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

#----------- Discover Access
  Scenario: Get item details for an item I have discover access
    Given "researcher1@intersect.org.au" has "discover" access to collection "cooee"
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Get annotations for item I have discover access
    Given "researcher1@intersect.org.au" has "discover" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Get primary text for item I have discover access
    Given "researcher1@intersect.org.au" has "discover" access to collection "cooee"
    When I make a JSON request for the catalog primary text page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Download document which exists but I have discover access
    Given "researcher1@intersect.org.au" has "discover" access to collection "cooee"
    When I make a JSON request for the document content page for file "1-001-plain.txt" for item "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code

  Scenario: Access collection details for which I have discover access
    Given "researcher1@intersect.org.au" has "discover" access to collection "cooee"
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

#----------- Read Access
  Scenario: Get item details for an item I have read access
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

  Scenario: Get annotations for item I have read access
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog annotations page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

  Scenario: Get primary text for item I have read access
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the catalog primary text page for "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

  Scenario: Download document which exists and I have read access
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the document content page for file "1-001-plain.txt" for item "cooee:1-001" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code

  Scenario: Access collection details for which I have read access
    Given "researcher1@intersect.org.au" has "read" access to collection "cooee"
    When I make a JSON request for the collection page for "cooee" with the API token for "researcher1@intersect.org.au"
    Then I should get a 200 response code
