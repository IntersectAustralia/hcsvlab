Feature: Displaying Items
  As a Researcher,
  I want to display item details

  Background:
    Given I have the usual roles and permissions
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And I am logged in as "data_owner@intersect.org.au"
    And "data_owner@intersect.org.au" has an api token

  Scenario: PARADISEC Open
    And I ingest the sample folder "paradisec/old/paradisec-test"
    And I reindex the collection "paradisec-test"
    And I am on the licences page
    And The Collection Lists table should have
      | collection_list | owner                       | licence     | licence_terms | collections    |
      | PARADISEC       | data_owner@intersect.org.au | Add Licence |               | paradisec-test |

    And I am on the catalog page for "paradisec-test:1-001"
    Then I should see a page with the title: "Alveo - paradisec-test:1-001"
    Then I should see "paradisec-test:1-001"
    And I should see "Display Document"
    And I should see "Documents"
    And I should see "1-001.txt"
    And I should see "1-001-plain.txt"
    And I should see "1-001-raw.txt"

    When I make a JSON request for the document content page for file "1-001-raw.txt" for item "paradisec-test:1-001" with the API token for "data_owner@intersect.org.au"
    Then I should get a 200 response code
    And the response should be:
    """
    This is the old raw text file 1-001-raw.txt.
    """
    And I am on the catalog page for "paradisec-test:1-002"
    Then I should see a page with the title: "Alveo - paradisec-test:1-002"
    Then I should see "paradisec-test:1-002"
    And I should see "Display Document"
    And I should see "Documents"
    And I should see "1-002-plain.txt"

    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "paradisec-test:1-002" with the API token for "data_owner@intersect.org.au"
    Then I should get a 200 response code
    And the response should be:
    """
    This is the old plain text file 1-002-plain.txt.
    """

    # PARADISEC Open but new
    And I clear the collection metadata for "paradisec-test"
    And I ingest the sample folder "paradisec/new/paradisec-test"
    And I reindex the collection "paradisec-test"

    And I am on the catalog page for "paradisec-test:1-001"
    Then I should see a page with the title: "Alveo - paradisec-test:1-001"
    Then I should see "paradisec-test:1-001"
    And I should see "Display Document"
    And I should see "Documents"
    And I should see "1-001.txt"
    And I should see "1-001-plain.txt"

    When I make a JSON request for the document content page for file "1-001-raw.txt" for item "paradisec-test:1-001" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code

    And I am on the catalog page for "paradisec-test:1-002"
    Then I should see a page with the title: "Alveo"
    Then I should see "Sorry, you have requested a document that doesn't exist."
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "paradisec-test:1-002" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code

    And I clear the collection metadata for "paradisec-test"
    And I ingest the sample folder "paradisec/new_closed/paradisec-test"
    And I reindex the collection "paradisec-test"

    And I am on the catalog page for "paradisec-test:1-001"
    Then I should see a page with the title: "Alveo"
    Then I should see "Sorry, you have requested a document that doesn't exist."
    When I make a JSON request for the document content page for file "1-001-raw.txt" for item "paradisec-test:1-001" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code

    And I am on the catalog page for "paradisec-test:1-002"
    Then I should see a page with the title: "Alveo"
    Then I should see "Sorry, you have requested a document that doesn't exist."
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "paradisec-test:1-002" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code


  Scenario: PARADISEC Closed
    And I clear the collection metadata for "paradisec-test"
    And I ingest the sample folder "paradisec/new_closed/paradisec-test"
    And I reindex the collection "paradisec-test"

    And I am on the catalog page for "paradisec-test:1-001"
    Then I should see a page with the title: "Alveo"
    Then I should see "Sorry, you have requested a document that doesn't exist."
    When I make a JSON request for the document content page for file "1-001-raw.txt" for item "paradisec-test:1-001" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code

    And I am on the catalog page for "paradisec-test:1-002"
    Then I should see a page with the title: "Alveo"
    Then I should see "Sorry, you have requested a document that doesn't exist."
    When I make a JSON request for the document content page for file "1-002-plain.txt" for item "paradisec-test:1-002" with the API token for "data_owner@intersect.org.au"
    Then I should get a 404 response code

