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
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the home page

  Scenario: Search returns correct results
    When I follow "austlit"
    Then I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Original, Raw, Text |
      | austlit:bolroma.xml | Original, Raw, Text |

  Scenario: Must be logged in to see search history
    Given I follow "researcher@intersect.org.au"
    And I follow "Logout"
    And I am on the search history page
    Then I should see "Please enter your email and password to log in"
