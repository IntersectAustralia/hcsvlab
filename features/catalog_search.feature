@ingest_qa_collections
Feature: Searching for items
  As a Researcher,
  I want to search for items
  So that I can add them to my item lists
# Don't need to test Blacklight comprehensively
# Just test any extensions to Blacklight we have made

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
      | data_owner@intersect.org.au | Researcher | One       |
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And "data_owner@intersect.org.au" has role "data_owner"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the home page

  @javascript
  Scenario: Search returns correct results
    When I have done a search with collection "austlit"
    Then I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Original, Raw, Text |
      | austlit:bolroma.xml | Original, Raw, Text |
