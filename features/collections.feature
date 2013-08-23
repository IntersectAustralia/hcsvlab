Feature: Collections
  As a Researcher,
  I want to view collections and their details

  Background:
  	Given I ingest "cooee:1-001" with id "hcsvlab:1"
  	And I ingest "auslit:adaessa" with id "hcsvlab:2"
  	And I have the usual roles and permissions
    And I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    And I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit	        | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"

  Scenario: View list of collections
    Given I am on the collections page
    Then I should see "Collections"
    And I should see "cooee"
    And I should see "austlit"
    And I should see "Select a collection to view"

  Scenario: Access collection details from item details page
    Given I am on the catalog page for "hcsvlab:1"
    And I follow "cooee"
    Then I should be on the collection page for "cooee"
    And I should see "cooee"
    And I should see "Collection Details"