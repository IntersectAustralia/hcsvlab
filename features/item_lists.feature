Feature: Managing Item Lists
  As a Researcher,
  I want to manage my item lists
  So that I can organise my collection

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher |    One    |
    And "researcher@intersect.org.au" has role "researcher"
    # And "diego@intersect.org.au" has item lists
    #   | name   |
    #   | Test 1 |
    #   | Test 2 |

  Scenario: Creating an Item List with selected items from search
  #check count after adding and that correct items are listed

  Scenario: Creating an Item List with no items and then adding to it later
  #check count and Item List is empty
  #check count after adding and that correct items are listed
  
  Scenario: Removing item from Item List

  Scenario: Accessing current user's Item Lists

  Scenario: Accessing other user's Item Lists

  Scenario: Sending Item List to Galaxy

  Scenario: Clearing an Item List

  Scenario: Deleting an Item List

