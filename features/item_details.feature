Feature: Displaying Items
  As a Researcher,
  I want to display item details

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
      | custom          | read        |
      | rirusyd         | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"

  Scenario: HCSVLAB-272 - Clicking through to a COOEE Item's details
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I am on the catalog page for "cooee:1-001"
    Then I should see "cooee:1-001"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see link "eng" to "http://www-01.sil.org/iso639-3/documentation.asp?id=eng"
    And I should see fields displayed
      | field                                     | value                                                   |
      | Collection                                | cooee                                                   |
      | Created                                   | 10/11/1791                                              |
      | Collection                                | cooee                                                   |
      | Word Count                                | 924                                                     |
      | Mode                                      | unspecified                                             |
      | Speech Style                              | unspecified                                             |
      | Interactivity                             | unspecified                                             |
      | Communication Context                     | unspecified                                             |
      | Discourse Type                            | letter                                                  |
      | Discourse Type                            | unspecified                                             |
      | Language (ISO 639-3 Code)                 | eng                                                     |
      | Audience                                  | unspecified                                             |
      | Documents                                 | 1-001#Original, 1-001#Raw, 1-001#Text                   |
      | Type                                      | Original, Raw, Text                                     |
      | Extent                                    | 5126, 5126, 4960                                        |
      | register                                  | Private Written                                         |
      | texttype                                  | Private Correspondence                                  |
      | http_ns_ausnc_org_au_schemas_localityName | New_South_Wales                                         |
      | source                                    | Niall, 1998                                             |
      | pages                                     | 10-11                                                   |
      | speaker                                   | 1-001addressee, 1-001author                             |
      | Date Group                                | 1790 - 1799                                             |
      | SPARQL endpoint                           | http://www.example.com/sparql/cooee                     |
    And I should not see "Development Extras"

  Scenario: Verify presence of every faceted field
    Given I ingest "custom:custom1" with id "hcsvlab:2"
    Given I am on the catalog page for "custom:custom1"
    Then I should see "custom:custom1"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see link "eng" to "http://www-01.sil.org/iso639-3/documentation.asp?id=eng"
    And I should see fields displayed
      | field                                     | value                                 |
      | Collection                                | custom                                |
      | Date Group                                | 1880 - 1889                           |
      | Mode                                      | spoken                                |
      | Speech Style                              | spontaneous                           |
      | Publication Status                        | published                             |
      | Written Mode                              | print                                 |
      | Interactivity                             | interview                             |
      | Communication Context                     | face_to_face                          |
      | Communication Medium                      | radio                                 |
      | Communication Setting                     | educational                           |
      | Audience                                  | massed                                |
      | Discourse Type                            | singing                               |
      | Language (ISO 639-3 Code)                 | eng                                   |
      | Type                                      | Original, Raw, Text                   |

  Scenario: Verify items with special characters in its id (1 dot, 2 underscores)
    Given I ingest "rirusyd:A_x3m_z0.34m" with id "hcsvlab:1"
    Given I am on the catalog page for "rirusyd:A_x3m_z0.34m"
    Then I should see "rirusyd:A_x3m_z0.34m"
    And I should see fields displayed
      | field          | value                 |
      | Identifier     | A_x3m_z0.34m          |
      | Creator        | Densil Cabrera        |

  Scenario: Verify items with special characters in its id (2 dots, 2 underscores)
    Given I ingest "rirusyd:A_x1.5m_z0.5m" with id "hcsvlab:1"
    Given I am on the catalog page for "rirusyd:A_x1.5m_z0.5m"
    Then I should see "rirusyd:A_x1.5m_z0.5m"
    And I should see fields displayed
      | field          | value                 |
      | Identifier     | A_x1.5m_z0.5m         |
      | Creator        | Densil Cabrera        |
