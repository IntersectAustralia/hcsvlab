Feature: Managing Item Lists
  As a Researcher,
  I want to manage my item lists
  So that I can organise my collection

  Background:
    Given I have "cooee:1-001" with id "hcsvlab:1" indexed
    Given I have "cooee:1-001" with id "hcsvlab:2" indexed
    Given I have "cooee:1-001" with id "hcsvlab:3" indexed
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I have done a search with corpus "cooee"
    And I should see the applied facet "Corpus" with the value "cooee"
    And I should get exactly 3 results
    And I should see "1 - 3 of 3"

  @javascript
  Scenario: Creating an Item List with all items from search
    And I should see "You searched for:"
    And I should see "Add All to list"
    And I follow "Add All to list"
    And I follow "Create New List"
    And I should see "Create New Item List"
    And I fill in "Name" with "Add All Test"
    And I press "Create List"
    And I should be on the item list page for "Add All Test"
    And I should see "Item list created successfully"
    And the item list "Add All Test" should have 3 items
    And the item list "Add All Test" should contain ids
      | pid       |
      | hcsvlab:1 |
      | hcsvlab:2 |
      | hcsvlab:3 |
    And I am on the item list page for "Add All Test"
    And I should see "1 - 3 of 3"

  @javascript
  Scenario: Creating an Item List with no items and then adding to it later
    And I should see "You searched for:"
    And I should see "Add Selected to list"
    And I follow "Add Selected to list"
    And I follow "Create New List"
    And I should see "Create New Item List"
    And I fill in "Name" with "Add Selected Test"
    And I press "Create List"
    And I should be on the item list page for "Add Selected Test"
    And the item list "Add Selected Test" should have 0 items
    And I have done a search with corpus "cooee"
    And I should get exactly 3 results
    And I should see "1 - 3 of 3"
    And I toggle the select all checkbox
    And I follow "Add Selected to list"
    And I follow "Add Selected Test"
    And I should be on the item list page for "Add Selected Test"
    And I should see "3 added to item list Add Selected Test"
    And the item list "Add Selected Test" should have 3 items
    And the item list "Add Selected Test" should contain ids
      | pid       |
      | hcsvlab:1 |
      | hcsvlab:2 |
      | hcsvlab:3 |
    And I am on the item list page for "Add Selected Test"
    And I should see "1 - 3 of 3"

  Scenario: Accessing other user's Item Lists
    Given I have users
      | email                  | first_name | last_name |
      | other@intersect.org.au | Researcher | One       |
    And "other@intersect.org.au" has role "researcher"
    And "other@intersect.org.au" has item lists
      | name   |
      | Test 1 |
    And I am on the item list page for "Test 1"
    And I should see "You are not authorized to access this page"

  Scenario: Clearing an Item List
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Clear Test |
    And the item list "Clear Test" has items hcsvlab:1, hcsvlab:2, hcsvlab:3
    And I am on the item list page for "Clear Test"
    And the item list "Clear Test" should have 3 items
    And I follow "Clear Item List"
    And I should see "3 cleared from item list Clear Test"

  Scenario: Deleting an Item List
    And "researcher@intersect.org.au" has item lists
      | name        |
      | Delete Test |
    And the item list "Delete Test" has items hcsvlab:1, hcsvlab:2, hcsvlab:3
    And I am on the item list page for "Delete Test"
    And the item list "Delete Test" should have 3 items
    And I follow the delete icon for item list "Delete Test"
    And I should see "Item list Delete Test deleted successfully"

#TODO check output maybe?

  Scenario: Sending Item List to Galaxy
