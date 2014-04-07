Feature: Managing Item Lists
  As a Researcher,
  I want to manage my item lists
  So that I can organise my collection

  Background:
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-002" with id "hcsvlab:2"
    Given I have the usual roles and permissions
    Given I have users
      | email                         | first_name | last_name |
      | researcher@intersect.org.au   | Researcher | One       |
      | researcher1@intersect.org.au  | Researcher | One       |
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    Given "researcher@intersect.org.au" has role "researcher"
    Given "researcher1@intersect.org.au" has role "researcher"
    Given I am logged in as "researcher@intersect.org.au"
    Given I have done a search with collection "cooee"
    Then I should see the applied facet "Collection" with the value "cooee"
    And I should get exactly 2 results
    And I should see "1 - 2 of 2"

  @javascript
  Scenario: Creating an Item List with empty name
    And I should see "You searched for:"
    And I should see "Add All to list"
    And I follow "Add All to list"
    And I follow "Create New List"
    And I wait 2 seconds
    And I should see "Create New Item List"
    And I fill in "Name" with ""
    And I press "Create List"
    Then I should see "Name can't be blank"

  @javascript
  Scenario: Creating an Item List with long name
    And I should see "You searched for:"
    And I should see "Add All to list"
    And I follow "Add All to list"
    And I follow "Create New List"
    And I wait 2 seconds
    And I should see "Create New Item List"
    And I fill in "Name" with "This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name This is a long item list name"
    And I press "Create List"
    Then I should see "Error trying to create an Item list, name too long (max. 255 characters)"

  @javascript
  Scenario: Creating an Item List with all items from search
    And I should see "You searched for:"
    And I should see "Add All to list"
    And I follow "Add All to list"
    And I follow "Create New List"
    And I wait 2 seconds
    And I should see "Create New Item List"
    And I fill in "Name" with "Add All Test"
    And I press "Create List"
    And I wait 5 seconds
    And I should be on the item list page for "Add All Test"
    And I should see "Item list created successfully"
    And the item list "Add All Test" should have 2 items
    And the item list "Add All Test" should contain handles
      | handle      |
      | cooee:1-001 |
      | cooee:1-001 |
    And I am on the item list page for "Add All Test"
    And I should see "1 - 2 of 2"

  @javascript
  Scenario: Adding 0 items to an existing item list
    And "researcher@intersect.org.au" has item lists
      | name          |
      | Existing Test |
    And the item list "Existing Test" has items hcsvlab:1
    And I wait 3 seconds
    And I have done a search with collection "non-existant"
    And I follow "Add All to list"
    And I follow "Existing Test"
    Then I should see "No items were selected to add to item list"

  @javascript
  Scenario: Creating an Item List with no items
    And I should see "You searched for:"
    And I should see "Add Selected to list"
    And I follow "Add Selected to list"
    And I follow "Create New List"
    And I wait 2 seconds
    And I should see "Create New Item List"
    And I fill in "Name" with "Add Selected Test"
    And I press "Create List"
    Then I should see "No items were selected to add to item list"

  Scenario: Accessing other user's Item Lists
    Given I have users
      | email                  | first_name | last_name |
      | other@intersect.org.au | Researcher | One       |
    And "other@intersect.org.au" has role "researcher"
    And "other@intersect.org.au" has item lists
      | name   |
      | Test 1 |
    And I am on the item list page for "Test 1"
    And I should see "You are not authorised to access this page"

  Scenario: Accessing other user's shared Item Lists
    Given I have users
      | email                  | first_name | last_name |
      | other@intersect.org.au | Researcher | One       |
    And "other@intersect.org.au" has role "researcher"
    And "other@intersect.org.au" has item lists
      | name   | shared |
      | Test 1 | true   |
    And the item list "Test 1" has items cooee:1-001, cooee:1-002
    And the item list "Test 1" should have 2 items
    And I am on the item list page for "Test 1"
    And I should see "cooee:1-001"
    And I should see "cooee:1-002"

  Scenario: Clearing an Item List
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Clear Test |
    And the item list "Clear Test" has items cooee:1-001, cooee:1-002
    And I wait 5 seconds
    And I am on the item list page for "Clear Test"
    And the item list "Clear Test" should have 2 items
    And I follow "Clear"
    And I should see "2 cleared from item list Clear Test"

  Scenario: Deleting an Item List
    And "researcher@intersect.org.au" has item lists
      | name        |
      | Delete Test |
    And the item list "Delete Test" has items cooee:1-001, cooee:1-002
    And I wait 5 seconds
    And I am on the item list page for "Delete Test"
    And the item list "Delete Test" should have 2 items
    And I follow the delete icon for item list "Delete Test"
    And I should see "Item list Delete Test deleted successfully"

  Scenario: User should be able to share his own item lists
    Given "researcher@intersect.org.au" has item lists
      | name       |
      | Share Test |
    Given the item list "Share Test" has items cooee:1-001, cooee:1-002
    When I am on the item list page for "Share Test"
    Then the item list "Share Test" should have 2 items
    And I should have the link "Share"

  Scenario: Sharing an Item List
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Share Test |
    And the item list "Share Test" has items cooee:1-001, cooee:1-002
    And I am on the item list page for "Share Test"
    And the item list "Share Test" should have 2 items
    And I follow "Share"
    And I should see "Item list Share Test is shared. Any user in the application will be able to see it."

  Scenario: Stop sharing an Item List
    And "researcher@intersect.org.au" has item lists
      | name       | shared |
      | Share Test | true   |
    And the item list "Share Test" has items cooee:1-001, cooee:1-002
    And I am on the item list page for "Share Test"
    And the item list "Share Test" should have 2 items
    And I follow "Stop Sharing"
    And I should see "Item list Share Test is not being shared anymore."

  Scenario: Stop sharing an Item List should no be possible for item list that does not belong to me
    Given "researcher1@intersect.org.au" has item lists
      | name       | shared |
      | Share Test | true   |
    Given the item list "Share Test" has items cooee:1-001, cooee:1-002
    When I am on the item list page for "Share Test"
    Then the item list "Share Test" should have 2 items
    And I should not have the link "Stop Sharing"

  Scenario: User should see a message when he has no access right to every item in the shared item list
    Given I ingest "auslit:adaessa" with id "hcsvlab:3"
    Given I ingest "auslit:bolroma" with id "hcsvlab:4"
    Given I have user "researcher1@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
    Given "researcher1@intersect.org.au" has item lists
      | name       | shared |
      | Share Test | true   |
    Given the item list "Share Test" has items cooee:1-001, cooee:1-002, austlit:adaessa, austlit:bolroma
    When I am on the item list page for "Share Test"
    Then the item list "Share Test" should have 4 items
    And I should see "You only have access to 2 out of 4 Items in this shared Item List. This is because you do not have access to the following collections: austlit. To gain access to more Collections, visit the Licence Agreements page."


#TODO check output maybe?

  Scenario: Sending item list to R
    Given "researcher@intersect.org.au" has item lists
      | name  |
      | Test1 |
    And the item list "Test1" has items cooee:1-001, cooee:1-002, hcsvlab:3
    And I am on the item list page for "Test1"
    And I follow "Use in Emu/R"
    Then I should see "Use Test1 in Emu/R"
    And I should see "Copy the following code into your R environment"
    And I should see "item_list <- client$get_item_list_by_id"
    And I follow "Download API key config file"
    And I should get the API config file for "researcher@intersect.org.au"
