@ingest_qa_collections
Feature: Searching for items using their metadata fields
  As a Researcher,
  I want to search for items
  So that I can add them to my item lists

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
      | data_owner@intersect.org.au | Researcher | One       |
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | austlit         | read        |
      | ice             | read        |
      | custom          | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And "data_owner@intersect.org.au" has role "data_owner"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the home page

  @javascript
  Scenario: Search for two simple term in all metadata joined with AND
    When I follow "Advanced search"
    And I fill in "Metadata" with "University AND Romance"
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |
      | austlit:bolroma.xml | A Romance of Canvas Town 	    | 1898 	       | Text, Original, Raw |

  @javascript
  Scenario: Search for term with tilde in all metadata
    When I follow "Advanced search"
    And I fill in "Metadata" with "Univarsoty~"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Title                         | Created Date | Type(s)             |
      | custom:utf8_test_1  | UTF-8 Test item               | 1986         | Text                |
      | austlit:adaessa.xml | Australian Essays             | 1886 	       | Text, Original, Raw |
      | austlit:bolroma.xml | A Romance of Canvas Town 	    | 1898 	       | Text, Original, Raw |

  @javascript
  Scenario: Search for term with asterisk in all metadata
    When I follow "Advanced search"
    And I fill in "Metadata" with "Correspon*"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

