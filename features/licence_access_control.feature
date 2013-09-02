Feature: Collection access control
  As a Data Owner, I only want users that have agreed
  to the licence for my collection to see that collection.

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                        | first_name   | last_name |
      | data_owner1@intersect.org.au | dataOwner1   | One       |
      | data_owner2@intersect.org.au | dataOwner2   | Two       |
    Given "data_owner1@intersect.org.au" has role "data owner"
    Given "data_owner2@intersect.org.au" has role "data owner"
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I ingest "auslit:bolroma" with id "hcsvlab:3"
    Given Collections ownership is
      |collection | ownerEmail                    |
      |austlit    | data_owner2@intersect.org.au  |
      |cooee      | data_owner1@intersect.org.au  |
    Given I ingest licences

  @javascript
  Scenario: Data Owner should be able to see all his collections
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      |collection |
      |austlit    |

  @javascript
  Scenario: Data Owner should be able to see all items of my collections
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Original, Raw, Text |
      | austlit:bolroma.xml | Original, Raw, Text |

  @javascript
  Scenario: Data Owner should be able to see the details of his items
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the catalog page for "hcsvlab:1"
    Then I should see "cooee:1-001"
    And I should see "Primary Document"
    And I should see "Documents"

  @javascript
  Scenario: User should not be able to see the details of items he has no permission
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the catalog page for "hcsvlab:2"
    Then I should see "You do not have sufficient access privileges to read this document"

  @javascript
  Scenario: User should be able to see collections for which he has discover access
    Given "data_owner2@intersect.org.au" has "discover" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      |collection |
      |austlit    |
      |cooee      |

  @javascript
  Scenario: User should see every item in a collection for which he has discover access
    Given "data_owner1@intersect.org.au" has "discover" access to collection "austlit"
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Original, Raw, Text |
      | austlit:bolroma.xml | Original, Raw, Text |

  @javascript
  Scenario: User should not be able to see details of items for which he has discover access
    Given "data_owner2@intersect.org.au" has "discover" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      |collection |
      |austlit    |
      |cooee      |
    Then I am on the catalog page for "hcsvlab:1"
    And I should see "You do not have sufficient access privileges to read this document"

  @javascript
  Scenario: User should be able to see collections for which he has read access
    Given "data_owner2@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      |collection |
      |austlit    |
      |cooee      |

  @javascript
  Scenario: User should see every item in a collection for which he has read access
    Given "data_owner1@intersect.org.au" has "read" access to collection "austlit"
    Given I am logged in as "data_owner1@intersect.org.au"
    Given I am on the home page
    And I have done a search with collection "austlit"
    And I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Original, Raw, Text |
      | austlit:bolroma.xml | Original, Raw, Text |

  @javascript
  Scenario: User should be able to see details of items for which he has read access
    Given "data_owner2@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "data_owner2@intersect.org.au"
    Given I am on the home page
    Then I should see only the following collections displayed in the facet menu
      |collection |
      |austlit    |
      |cooee      |
    Then I am on the catalog page for "hcsvlab:1"
    And I should see "cooee:1-001"
    And I should see "Primary Document"
    And I should see "Documents"
