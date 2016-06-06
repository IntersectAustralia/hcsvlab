Feature: Document Audit
  As a PARADISEC Data Owner,
  I want to be able to audit who has downloaded which Documents.

  Background:
    Given I have the usual roles and permissions
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And I have a user "researcher@intersect.org.au" with role "researcher"
    And I ingest "cooee:1-001"
    And I have user "researcher@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |

  Scenario: Document Audit link is visible
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the admin page
    Then I should see "View Document Audit"

  Scenario: No document audits
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the document audit page
    Then I should see "Alveo Document Audit"
    And I should see "No documents have been downloaded yet."

  Scenario: Single download is recorded
    Given I am logged in as "researcher@intersect.org.au"
    And I am on the catalog page for "cooee:1-001"
    And I follow "1-001-plain.txt"
    Then I am logged out
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the document audit page
    Then I should see "Showing 1 audit"
    And I should see "document-audits" table with
      | Collection | Item       | Document         | User Name    | User Email                  |
      | cooee      | cooee:1-001| 1-001-plain.txt  | Fred Bloggs  | researcher@intersect.org.au |

  Scenario: Item List zip download is recorded
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name  |
      | Test1 |
    And the item list "Test1" has items cooee:1-001
    And I am on the item list page for "Test1"
    And I follow element with id "download_all_as_zip"
    Then I am logged out
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the document audit page
    Then I should see "Showing 3 audits"
    Then I should see a table with the following rows in any order:
      | Collection | Item         | Document         | User Name    | User Email                  |
      | cooee      | cooee:1-001  | 1-001-plain.txt  | Fred Bloggs  | researcher@intersect.org.au |
      | cooee      | cooee:1-001  | 1-001-raw.txt    | Fred Bloggs  | researcher@intersect.org.au |
      | cooee      | cooee:1-001  | 1-001.txt        | Fred Bloggs  | researcher@intersect.org.au |

  Scenario: Download Document Audit CSV
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name  |
      | Test1 |
    And the item list "Test1" has items cooee:1-001
    And I am on the item list page for "Test1"
    And I follow element with id "download_all_as_zip"
    Then I am logged out
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the document audit page
    Then I should see "Download CSV"
    Then I follow "Download CSV"
    Then I should get a CSV file called "document_audit.csv" with the following metrics:
    """
    collection,item,document,user_name,user_email
    cooee,cooee-1-001,cooee/1-001/1-001.txt,Fred Bloggs,researcher@intersect.org.au
    cooee,cooee-1-001,cooee/1-001/1-001-raw.txt,Fred Bloggs,researcher@intersect.org.au
    cooee,cooee-1-001,cooee/1-001/1-001-plain.txt,Fred Bloggs,researcher@intersect.org.au
    """

  Scenario: Unauthorised user cannot see the document audit page
    Given I am logged in as "researcher@intersect.org.au"
    And I am on the document audit page
    Then I should see "You are not authorised to access this page."