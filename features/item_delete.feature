Feature: Deleting Items
  As a Data Owner,
  I want to delete items from my collection

  Background:
    Given I have the usual roles and permissions
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And I have a user "researcher@intersect.org.au" with role "researcher"
    And I ingest "cooee:1-001"
    And I have user "researcher@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |

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

  @create_collection
  Scenario: Verify direct url to delete item won't work for users apart from the item owner
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "test"
    And I am logged in as "researcher@intersect.org.au"
    When I go to the delete item web path for "test:item1"
    Then I should get a security error "You are not authorised to access this page"

  @create_collection
  Scenario: Successfully deleting an item ends on the home page
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I reindex the collection "test"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the catalog page for "test:item1"
    When I click the delete icon for item "test:item1"
    And The popup text should contain "Are you sure you want to delete this document?"
    And I confirm the popup
    Then I should be on the home page

  @create_collection
  Scenario: Collection doesn't list item after item is deleted
    Given I ingest a new collection "test" through the api with the API token for "data_owner@intersect.org.au"
    And I make a JSON post request for the collection page for id "test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document1.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item1", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document1.txt", "@type": "foaf:Document", "dcterms:identifier": "document1.txt", "dcterms:title": "document1#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item1", "hcsvlab:display_document": { "@id": "document1.txt" }, "hcsvlab:indexable_document": { "@id": "document1.txt" } } ] } } ] |
    And I make a JSON post request for the collection page for id "test" with the API token for "data_owner@intersect.org.au" with JSON params
      | items |
      | [ { "documents": [ { "identifier": "document2.txt", "content": "A Test." } ], "metadata": { "@context": { "ausnc": "http://ns.ausnc.org.au/schemas/ausnc_md_model/", "corpus": "http://ns.ausnc.org.au/corpora/", "dc": "http://purl.org/dc/terms/", "dcterms": "http://purl.org/dc/terms/", "foaf": "http://xmlns.com/foaf/0.1/", "hcsvlab": "http://hcsvlab.org/vocabulary/" }, "@graph": [ { "@id": "item2", "@type": "ausnc:AusNCObject", "ausnc:document": [ { "@id": "document2.txt", "@type": "foaf:Document", "dcterms:identifier": "document2.txt", "dcterms:title": "document2#Text", "dcterms:type": "Text" } ], "dcterms:identifier": "item2", "hcsvlab:display_document": { "@id": "document2.txt" }, "hcsvlab:indexable_document": { "@id": "document2.txt" } } ] } } ] |
    And I reindex the collection "test"
    And I am logged in as "data_owner@intersect.org.au"
    And I am on the catalog page for "test:item1"
    And I click the delete icon for item "test:item1"
    And The popup text should contain "Are you sure you want to delete this document?"
    And I confirm the popup
    When I have done a search with collection "test"
    Then I should see "blacklight_results" table with
      | Identifier  | Type(s) |
      | test:item2  | Text    |