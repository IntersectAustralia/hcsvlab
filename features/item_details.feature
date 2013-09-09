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
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | cooee           | read        |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the catalog page for "hcsvlab:1"

  Scenario: HCSVLAB-272 - Clicking through to an COOEE Item's details
    And I should see "cooee:1-001"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see link "eng" to "http://www-01.sil.org/iso639-3/documentation.asp?id=eng"
    And I should see fields displayed
      | field                                     | value                                 |
      | Collection                                | cooee                                 |
      | Created                                   | 10/11/1791                            |
      | Collection                                | cooee                                 |
      | Word Count                                | 924                                   |
      | Mode                                      | unspecified                           |
      | Speech Style                              | unspecified                           |
      | Interactivity                             | unspecified                           |
      | Communication Context                     | unspecified                           |
      | Discourse Type                            | letter                                |
      | Discourse Type                            | unspecified                           |
      | Language (ISO 639-3 Code)                 | eng                                   |
      | Audience                                  | unspecified                           |
      | Documents                                 | 1-001#Original, 1-001#Raw, 1-001#Text |
      | Type                                      | Original, Raw, Text                   |
      | Extent                                    | 5126, 5126, 4960                      |
      | register                                  | Private Written                       |
      | texttype                                  | Private Correspondence                |
      | http_ns_ausnc_org_au_schemas_localityName | New_South_Wales                       |
      | source                                    | Niall, 1998                           |
      | pages                                     | 10-11                                 |
      | speaker                                   | 1-001addressee, 1-001author           |
      | date_group                                | 1790 - 1799                           |
    And I should not see "Development Extras"


#
# Preserve format of Primary Document (HCSVLAB-433)
# And I should see "Dear Sir,\n"
# And show me the page
# And I follow "1-001-plain.txt"
# Then I should get a 200 response code
# Then I should get the primary text for "cooee:1-001"