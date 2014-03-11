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
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"

  @javascript
  Scenario: View list of collections
    Given I am on the collections page
    Then I should see "Collections"
    And I should see "cooee"
    And I should see "austlit"
    And I should see "Select a collection to view"

  @javascript
  Scenario: Access collection details from the collections page
    Given I am on the collections page
    And I follow "austlit"
    Then I should see "austlit"
    And I should see "Collection Details"
    And I should see "Title: AustLit "
    And I should see "Access Rights: See AusNC Terms of Use "
    And I should see "Created: 2000 to present "
    And I should see "Is Part Of: Australian National Corpus - http://www.ausnc.org.au "
    And I should see "Language: eng"
    And I should see "Owner: University of Queensland. "
    And I should see "sparql endpoint: http://localhost:8984/openrdf-sesame/repositories/austlit"
    And I should not see "Back to Licence Agreements"

  @javascript
  Scenario: Access collection details from item details page
    Given "researcher@intersect.org.au" has "read" access to collection "cooee"
    Given I am on the catalog page for "cooee:1-001"
    And I follow "cooee"
    Then I should be on the collection page for "cooee"
    And I should see "cooee"
    And I should see "Collection Details"
    And I should see "Title: Corpus of Oz Early English "
    And I should see "Access Rights: See AusNC Terms of Use "
    And I should see "Created: 2004 "
    And I should see "Extent: 1353 text samples, 2,000,000 words "
    And I should see "Language: eng"
    And I should see "Owner: None. Individual owner is Clemens Fritz. "
    And I should see "sparql endpoint: http://localhost:8984/openrdf-sesame/repositories/cooee"
    And I should not see "Back to Licence Agreements"
