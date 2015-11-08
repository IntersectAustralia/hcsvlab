Feature: Deleting Items
  As a Data Owner,
  I want to delete items from my collection

  Background:
    Given I have the usual roles and permissions
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And I have a user "researcher@intersect.org.au" with role "researcher"
    And I ingest "cooee:1-001"

  Scenario: Verify delete item button is visible for item owner (one item ingested)
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the catalog page for "cooee:1-001"
    Then I should see a page with the title: "Alveo - cooee:1-001"
    And I should see "cooee:1-001"
    And I should see link "Delete Item" to "/catalog/cooee/1-001/delete"

  Scenario: Verify delete item button is visible for item owner (multiple items ingested)
    Given I ingest "cooee:1-002"
    And I am logged in as "data_owner@intersect.org.au"
    When I am on the catalog page for "cooee:1-001"
    Then I should see a page with the title: "Alveo - cooee:1-001"
    And I should see "cooee:1-001"
    And I should see link "Delete Item" to "/catalog/cooee/1-001/delete"

  Scenario: Verify delete item button isn't visible for users apart from the item owner
    Given I am logged in as "researcher@intersect.org.au"
    And I have user "researcher@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I am on the catalog page for "cooee:1-001"
    Then I should see a page with the title: "Alveo - cooee:1-001"
    And I should see "cooee:1-001"
    And I should not see link "Delete Item" to "/catalog/cooee/1-001/delete"

  Scenario: Verify direct url to delete item won't work for users apart from the item owner
    Given I ingest "cooee:1-001"
    And I am logged in as "researcher@intersect.org.au"
    And I have user "researcher@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    When I go to the delete item web path for "cooee:1-001"
    Then I should get a security error "You are not authorised to access this page"

  Scenario: Successfully deleting an item ends on the home page
    Given I ingest "cooee:1-001"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the catalog page for "cooee:1-001"
    When I click the delete icon for item "cooee:1-001"
    And The popup text should contain "Are you sure you want to delete this document?"
    And I confirm the popup
    Then I should be on the home page

  Scenario: Collection doesn't list item after item is deleted
    Given I ingest "cooee:1-001"
    And I ingest "cooee:1-002"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the catalog page for "cooee:1-001"
    And I click the delete icon for item "cooee:1-001"
    And The popup text should contain "Are you sure you want to delete this document?"
    And I confirm the popup
    When I have done a search with collection "cooee"
    Then I should see "blacklight_results" table with
      | Identifier  | Type(s) |
      | cooee:1-002 | Text    |
