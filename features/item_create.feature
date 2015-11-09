Feature: Creating Items
  As a Collection Owner,
  I want to add a new item to my collection via the web app

  Background:
    Given I have the usual roles and permissions
    And I have a user "admin@intersect.org.au" with role "admin"
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And I have a user "researcher@intersect.org.au" with role "researcher"
    And I ingest "cooee:1-001"
    And Collections ownership is
      | collection | owner_email                 |
      | cooee      | data_owner@intersect.org.au |

  Scenario: Verify add item button is visible for collection owner
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the collection page for "cooee"
    Then I should see link "Add New Item" to "/add-item/cooee"

  Scenario Outline: Verify add item button is not visible for users other than the collection owner
    Given I am logged in as "<user>"
    When I am on the collection page for "cooee"
    Then I should not see link "Add New Item" to "/add-item/cooee"
    Examples:
    | user |
    | admin@intersect.org.au      |
    | researcher@intersect.org.au |

  Scenario: Verify add item button goes to new item form page
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the collection page for "cooee"
    When I follow element with id "add_new_item"
    Then I should be on the add item page for "cooee"

  Scenario Outline: Verify users other than the collection owner are not authorised to load add item page
    Given I am logged in as "<user>"
    When I am on the add item page for "cooee"
    Then I should see "You are not authorised to access this page."
    Examples:
    | user |
    | admin@intersect.org.au      |
    | researcher@intersect.org.au |

  Scenario: Verify add item page has expected form fields
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the add item page for "cooee"
    Then I should see "Create Item"
    And I should see "Item Name:"
    And I should see "Item Title:"
    And I should see "Additional Metadata"
    And I should see "See searchable fields for suggestions"
    And I should see link "searchable fields" to "/catalog/searchable_fields"
    And I should see "Add Metadata Field"
    And I should see button with text "Add Metadata Field"
    And I should see link "Cancel" to "/catalog/cooee"
    And I should see "Create"
    And I should see button "Create"

  Scenario: Verify add metadata key/value fields not visible by default
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the add item page for "cooee"
    Then I should not see "Key:"
    And I should not see "Value:"

  @javascript
  Scenario: Verify add metadata key/value fields are visible after clicking add metadata field button
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "cooee"
    When I click "Add Metadata Field"
    Then I should see "Key:"
    And I should see "Value:"

  Scenario Outline: Verify item name and title are required
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "cooee"
    When I fill in "item_name" with "<name>"
    And I fill in "item_title" with "<title>"
    And I press "Create"
    Then I should be on the add item page for "cooee"
    And I should see "<response>"
  Examples:
    | name | title | response |
    |      | Test  | Required field 'item name' is missing  |
    | test |       | Required field 'item title' is missing |

  Scenario: Verify that an item name needs to be unique within a collection
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "cooee"
    When I fill in "item_name" with "1-001"
    And I fill in "item_title" with "Duplicate Item"
    And I press "Create"
    Then I should be on the add item page for "cooee"
    And I should see "An item with the name '1-001' already exists in this collection"

  @create_collection
  Scenario Outline: Create an item with just the required fields
    Given I ingest a new collection "<collection_name>" through the api with the API token for "data_owner@intersect.org.au"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "<collection_name>"
    When I fill in "item_name" with "<name>"
    And I fill in "item_title" with "<title>"
    And I press "Create"
    Then I should be on the home page
    And I should see "Created new item: <sanitised_name> ×"
    And I should see "Sorry, the item you requested is being indexed and will be available shortly. ×"
  Examples:
    | collection_name | name        | sanitised_name | title        |
    | test            | test        | test           | Test         |
    | test            | test spaces | testspaces     | Test Spaces  |

  # Todo: resolve reindex_all needing to be run in the following scenarios in order to view the page

  @create_collection
  Scenario Outline: Create an item with just the required fields and view that item
    Given I ingest a new collection "<collection_name>" through the api with the API token for "data_owner@intersect.org.au"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "<collection_name>"
    And I fill in "item_name" with "<name>"
    And I fill in "item_title" with "<title>"
    And I press "Create"
    And I reindex all
    When I go to the catalog page for "<collection_name>:<sanitised_name>"
    Then I should see a page with the title: "Alveo - <collection_name>:<sanitised_name>"
    And I should see "<collection_name>:<sanitised_name>"
    And I should see "This Item has no display document"
    And I should see "This Item has no documents"
    And I should see "Item Details"
    And I should see "Title: <title>"
    And I should see "Identifier: <sanitised_name>"
    And I should see "Collection: <collection_name>"
    And I should see "SPARQL endpoint http://www.example.com/sparql/<collection_name>"
  Examples:
    | collection_name | name        | sanitised_name | title        |
    | test            | test        | test           | Test         |
    | test            | test2       | test2          | Test Spaces  |
    | test            | test3 space | test3space     | Test Spaces  |

  @javascript @create_collection
  Scenario Outline: Create an item with a set of additional metadata
    Given I ingest a new collection "<collection_name>" through the api with the API token for "data_owner@intersect.org.au"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "<collection_name>"
    And I click "Add Metadata Field"
    When I fill in "item_name" with "test"
    And I fill in "item_title" with "Test"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    And I reindex all
    And I go to the catalog page for "<collection_name>:test"
    Then I should see a page with the title: "Alveo - <collection_name>:test"
    And I should see "This Item has no display document"
    And I should see "This Item has no documents"
    And I should see "Item Details"
    And I should see "Title: Test"
    And I should see "Identifier: test"
    And I should see "Collection: <collection_name>"
    And I should see "SPARQL endpoint http://"
    And I should see "/sparql/<collection_name>"
    And I should see "<expected>"
  Examples:
    | collection_name | key        | value   | expected        |
    | test            | dc:extent  | foo     | Extent: foo     |
    | test            | dc:ex tent | foo bar | Extent: foo bar |

  @javascript @create_collection
  Scenario Outline: Verify providing an empty metadata field returns an error response
    Given I ingest a new collection "<collection_name>" through the api with the API token for "data_owner@intersect.org.au"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the add item page for "<collection_name>"
    And I click "Add Metadata Field"
    When I fill in "item_name" with "test"
    And I fill in "item_title" with "Test"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    Then I should be on the add item page for "<collection_name>"
    Then I should see "<response>"
  Examples:
    | collection_name | key | value | response |
    | test            |     | foo   | An additional metadata field is missing a key      |
    | test            | bar |       | Additional metadata field 'bar' is missing a value |