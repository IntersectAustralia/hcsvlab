Feature: Creating Collections
  As a Data Owner or Admin,
  I want to create a collection via the web app

  Background:
    Given I have the usual roles and permissions
    And I have a user "admin@intersect.org.au" with role "admin"
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And I have a user "researcher@intersect.org.au" with role "researcher"

  Scenario: Verify create collection button is visible for admin
    Given I am logged in as "admin@intersect.org.au"
    When I am on the collections page
    And I should see link "Create New Collection" to "/catalog-create"

  Scenario: Verify create collection button is visible for data owner
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the collections page
    Then I should see link "Create New Collection" to "/catalog-create"

  Scenario: Verify create collection button is not visible for researcher
    Given I am logged in as "researcher@intersect.org.au"
    When I am on the collections page
    Then I should not see link "Create New Collection" to "/catalog-create"

  Scenario: Verify create new collection button goes to new collection form page
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the collections page
    When I follow element with id "Create New Collection"
    Then I should be on the create collection page

  Scenario: Verify researcher is not authorised to load create collection page
    Given I am logged in as "researcher@intersect.org.au"
    When I am on the create collection page
    Then I should see "You are not authorised to access this page."

  Scenario: Verify create collection page has expected form fields
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the create collection page
    Then I should see "Create Collection"
    And I should see "Collection Name:"
    And I should see "Collection Title:"
    And I should see "Collection Owner:"
    And I should see "Collection Abstract"
    And I should see "Licence"
    And I should see "Privacy: (Approval required for collection access)"
    And the "Privacy: (Approval required for collection access)" checkbox should be checked
    And I should see "Additional Metadata"
    And I should see "See the RDF Names of searchable fields for examples of accepted metadata field names."
    And I should see link "searchable fields" to "/catalog/searchable_fields"
    And I should see "Note: If the context for a field you want to enter is not available in the default schema then you must provide the full URI for that metadata field."
    And I should see link "default schema" to "/schema/json-ld"
    And I should see "Add Metadata Field"
    And I should see button with text "Add Metadata Field"
    And I should see link "Cancel" to "/catalog"
    And I should see "Create"
    And I should see button "Create"

  Scenario: Verify add metadata name/value fields not visible by default
    Given I am logged in as "data_owner@intersect.org.au"
    When I am on the create collection page
    Then I should not see "Name: Value: "

  @javascript
  Scenario: Verify add metadata name/value fields visible after clicking add metadata field button
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    When I click "Add Metadata Field"
    Then the "additional_key[]" field should contain ""
    And the "additional_value[]" field should contain ""

  @create_collection
  Scenario: Verify creating a collection with just a the required fields
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    When I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I press "Create"
    Then I should be on the collection page for "test"
    And I should see "New collection 'test' (http://www.example.com/catalog/test) created"
    And I should see "test"
    And I should see "Collection Details"
    And I should see "RDF Type: dcmitype:Collection"
    And I should see "Title: Test Title"
    And I should see "Owner: Test Owner"
    And I should see "Abstract: Test Abstract"
    And I should see "SPARQL Endpoint: http://www.example.com/sparql/test"

  @create_collection
  Scenario Outline: Verify creating a collection sanitises the collection name
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    When I fill in "collection_name" with "<name>"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I press "Create"
    Then I should be on the collection page for "<sanitised_name>"
    And I should see "New collection '<sanitised_name>' (http://www.example.com/catalog/<sanitised_name>) created"
    And I should see "<sanitised_name>"
    And I should see "Collection Details"
    And I should see "RDF Type: dcmitype:Collection"
    And I should see "Title: Test Title"
    And I should see "Owner: Test Owner"
    And I should see "Abstract: Test Abstract"
    And I should see "SPARQL Endpoint: http://www.example.com/sparql/<sanitised_name>"
  Examples:
    | name             | sanitised_name   |
    | TESTUPPERCASE    | testuppercase    |
    | test with spaces | testwithspaces   |
    | test/with/slash  | testwithslash    |
    | test.with.period | testwithperiod   |
    | Test with/allthe/Sanitisations.to be.cleaned | testwithallthesanitisationstobecleaned|

  @create_collection
  Scenario Outline: Verify collection name, title, owner and abstract are required
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    When I fill in "collection_name" with "<name>"
    And I fill in "collection_title" with "<title>"
    And I fill in "collection_owner" with "<owner>"
    And I fill in "collection_abstract" with "<abstract>"
    And I press "Create"
    Then I should be on the create collection page
    And I should see "<response>"
  Examples:
    | name | title | owner | abstract | response |
    |      | Test  | Test  | Test     | Required field 'collection name' is missing  |
    | test |       | Test  | Test     | Required field 'collection title' is missing |
    | test | Test  |       | Test     | Required field 'collection owner' is missing |
    | test | Test  | Test  |          | Required field 'collection abstract' is missing |

  @create_collection @javascript
  Scenario Outline: Verify creating a collection a set of additional metadata
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    And I click "Add Metadata Field"
    When I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    Then I should be on the collection page for "test"
    And I should see "test"
    And I should see "Collection Details"
    And I should see "RDF Type: dcmitype:Collection"
    And I should see "Title: Test Title"
    And I should see "Owner: Test Owner"
    And I should see "Abstract: Test Abstract"
    And I should see "<expected>"
  Examples:
    | key        | value   | expected        |
    | dc:extent  | foo     | Extent: foo     |
    | dc:ex tent | foo bar | Extent: foo bar |

  @create_collection @javascript
  Scenario Outline: Verify providing an empty metadata field returns an error response
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    And I click "Add Metadata Field"
    When I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I fill in "additional_key[]" with "<key>"
    And I fill in "additional_value[]" with "<value>"
    And I press "Create"
    Then I should be on the create collection page
    And I should see "<response>"
  Examples:
    | key | value | response|
    |     | bar   | An additional metadata field is missing a name     |
    | foo |       | Additional metadata field 'foo' is missing a value |

  @create_collection @javascript
  Scenario: Verify form is re-populated with previous input if an error occurs
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    And I click "Add Metadata Field"
    When I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I uncheck "approval_required"
    And I fill in "additional_key[]" with "foo"
    And I fill in "additional_value[]" with ""
    And I press "Create"
    Then I should be on the create collection page
    And I should see " Additional metadata field 'foo' is missing a value"
    And the "collection_name" field should contain "test"
    And the "collection_title" field should contain "Test Title"
    And the "collection_owner" field should contain "Test Owner"
    And the "collection_abstract" field should contain "Test Abstract"
    And the "Privacy: (Approval required for collection access)" checkbox should not be checked
    And the "additional_key[]" field should contain "foo"
    And the "additional_value[]" field should contain ""

  @create_collection
  Scenario: Verify the collection name needs to be unique within the system
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    And I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I press "Create"
    When I am on the create collection page
    And I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title 2"
    And I fill in "collection_owner" with "Test Owner 2"
    And I fill in "collection_abstract" with "Test Abstract 2"
    And I press "Create"
    Then I should be on the create collection page
    And I should see "A collection with the name 'test' already exists"

  @create_collection
  Scenario: Verify licence can be selected when creating a collection
    Given I am logged in as "data_owner@intersect.org.au"
    And I ingest licences
    And I am on the create collection page
    And I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    When I select "Creative Commons v3.0 BY-NC" from "licence_id"
    And I press "Create"
    Then I should be on the collection page for "test"
    And I should see "New collection 'test' (http://www.example.com/catalog/test) created"
    And I should see "test"
    And I should see "Collection Details"
    And I should see "RDF Type: dcmitype:Collection"
    And I should see "Title: Test Title"
    And I should see "Owner: Test Owner"
    And I should see "Abstract: Test Abstract"
    And I should see "SPARQL Endpoint: http://www.example.com/sparql/test"

  @create_collection
  Scenario: Assign licence to a Collection
    Given I am logged in as "data_owner@intersect.org.au"
    And I ingest licences
    And I am on the create collection page
    And I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    When I select "Creative Commons v3.0 BY-NC" from "licence_id"
    And I press "Create"
    And I am on the licences page
    Then The Collection table should have
      | collection | collection_list | licence                     | licence_terms      |
      | test       |                 | Creative Commons v3.0 BY-NC | View Licence Terms |

  @create_collection
  Scenario Outline: Create a collection and set the privacy
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the create collection page
    And I fill in "collection_name" with "test"
    And I fill in "collection_title" with "Test Title"
    And I fill in "collection_owner" with "Test Owner"
    And I fill in "collection_abstract" with "Test Abstract"
    And I <action> "approval_required"
    When I press "Create"
    And I am on the licences page
    Then The Collection table should have
      | collection | approval_required    | licence     | licence_terms |
      | test       | <displayed_approval> | Add Licence |               |
  Examples:
    | action  | displayed_approval  |
    | check   | required            |
    | uncheck | not required        |
