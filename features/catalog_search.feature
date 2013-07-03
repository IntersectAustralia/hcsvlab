Feature: Searching for items
  As a Researcher,
  I want to search for items
  So that I can add them to my item lists
# Don't need to test Blacklight comprehensively
# Just test any extensions to Blacklight we have made

  Background:
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-001" with id "hcsvlab:2"
    Given I ingest "cooee:1-001" with id "hcsvlab:3"
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher |    One    |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"

@javascript
  Scenario: Creating an Item List with selected items from search

  And I am on the home page
  And pause
  # And show me the page
  #check count after adding and that correct items are listed

  Scenario: Creating an Item List with no items and then adding to it later
  #check count and Item List is empty
  #check count after adding and that correct items are listed

  Scenario: Accessing current user's Item Lists

  Scenario: Accessing other user's Item Lists

  Scenario: Sending Item List to Galaxy

  Scenario: Clearing an Item List

  Scenario: Deleting an Item List

