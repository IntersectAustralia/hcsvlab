Feature: Displaying Items
  As a Researcher,
  I want to display item details

  Background:
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "cooee:1-001" with id "hcsvlab:2"
    Given I ingest "cooee:1-001" with id "hcsvlab:3"
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I have done a search with corpus "cooee"
    And I should see the applied facet "Collection" with the value "cooee"
    And I should get exactly 3 results
    And I should see "1 - 3 of 3"

  @javascript
  Scenario: Clicking through to an Item's details
    And I should see "cooee:1-001"
    And I follow "cooee:1-001"
    #
    # General
    #
    And I should see "cooee:1-001"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see "Collection"
    And I should see "Created"
    And I should see "Mode"
    And I should see "Speech Style"
    And I should see "Interactivity"
    And I should see "Communication Context"
    And I should see "Audience"
    And I should see "Discourse Type"
    And I should see "Language (ISO 639-3 Code)"
    And I should see "Type"
    #
    # Preserve format of Primary Document (HCSVLAB-433)
    # And I should see "Dear Sir,\n"
