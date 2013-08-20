Feature: Searching for items
  As a Researcher,
  I want to search for items
  So that I can add them to my item lists
# Don't need to test Blacklight comprehensively
# Just test any extensions to Blacklight we have made

  Background:
    Given I have "cooee:1-001" with id "hcsvlab:1" indexed
    Given I have "cooee:1-001" with id "hcsvlab:2" indexed
    Given I have "cooee:1-001" with id "hcsvlab:3" indexed
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the home page

  Scenario: Search returns correct results
    And I follow "cooee"
    And I should see "blacklight_results" table with
      | Identifier  | Type(s)             |
      | cooee:1-001 | Original, Raw, Text |
      | cooee:1-001 | Original, Raw, Text |
      | cooee:1-001 | Original, Raw, Text |

