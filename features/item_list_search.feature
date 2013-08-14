@javascript
Feature: Searching item lists
  As a Researcher,
  I want to search my item lists
  So that I can analyse my collection

  Background:
    Given I have "cooee:1-001" with id "hcsvlab:1" indexed
    Given I have "cooee:1-001" with id "hcsvlab:2" indexed
    Given I have "cooee:1-001" with id "hcsvlab:3" indexed
    Given I have "auslit:adaessa" with id "hcsvlab:4" indexed
    Given I have "auslit:bolroma" with id "hcsvlab:5" indexed
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    And I have done a search with collection "cooee"

  Scenario: Doing a concordance search for "family"
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Concordance search |
    And the item list "Concordance search" has items hcsvlab:1, hcsvlab:4
    And I am on the item list page for "Concordance search"
    And the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    When I fill in "Concordance search for" with "family"
    And I press "execute_concordance_search"
    Then concordance search for "family" in item list "Concordance search" should show this results
      | documentTitle | textBefore                         | textHighlighted | textAfter                       |
      | cooee:1-001   | Banks & to the Ladys of your       | family          | .The hurry in which I write you |

  Scenario: Doing a concordance search for "make"
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Concordance search |
    And the item list "Concordance search" has items hcsvlab:1, hcsvlab:4
    And I am on the item list page for "Concordance search"
    And the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    When I fill in "Concordance search for" with "make"
    And I press "execute_concordance_search"
    Then concordance search for "make" in item list "Concordance search" should show this results
      | documentTitle      | textBefore                                     | textHighlighted | textAfter                                 |
      | cooee:1-001        | get the small fish, of which they              | make            |  no account in the Summer nor can          |
      | cooee:1-001        | will, Sir, be so obliging as to                | make            |  my Compliments acceptable to Lady Banks & |
      | auslit:adaessa.xml | of such a current; and, (I will                | make            |  a clean breast of it at once!),           |
      | auslit:adaessa.xml | which distinguish the genial littérateur , and | make            |  his work, as one of my fellow             |

  Scenario: Doing a concordance search for "concordance"
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Concordance search |
    And the item list "Concordance search" has items hcsvlab:1, hcsvlab:4
    And I am on the item list page for "Concordance search"
    And the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    When I fill in "Concordance search for" with "concordance"
    And I press "execute_concordance_search"
    Then concordance search for "concordance" in item list "Concordance search" should show not matches found message

  Scenario: Doing a failing concordance search for "dog-"
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Concordance search |
    And the item list "Concordance search" has items hcsvlab:1, hcsvlab:4
    And I am on the item list page for "Concordance search"
    And the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    When I fill in "Concordance search for" with "dog-"
    And I press "execute_concordance_search"
    Then concordance search for "dog-" in item list "Concordance search" should show error

  Scenario: Doing a failing concordance search for "dog like"
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Concordance search |
    And the item list "Concordance search" has items hcsvlab:1, hcsvlab:4
    And I am on the item list page for "Concordance search"
    And the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    When I fill in "Concordance search for" with "dog-"
    And I press "execute_concordance_search"
    Then concordance search for "dog like" in item list "Concordance search" should show error

  Scenario: Doing a frequency search for simple words (can)
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Frequency search |
    And the item list "Frequency search" has items hcsvlab:5
    And I am on the item list page for "Frequency search"
    And the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    When I select "Collection" from "Facet"
    When I fill in "Frequency search for" with "can"
    And I press "execute_frequency_search"
    Then frequency search for "can" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | auslit     | 1                 | 1         | 131             | 89728      |

  Scenario: Doing a frequency search for words word (what)
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Frequency search |
    And the item list "Frequency search" has items hcsvlab:5
    And I am on the item list page for "Frequency search"
    And the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    When I select "Created" from "Facet"
    When I fill in "Frequency search for" with "what"
    And I press "execute_frequency_search"
    Then frequency search for "what" in item list "Frequency search" should show this results
      | facetValue      | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | 1890 - 1899     | 1                 | 1         | 219             | 89728      |

  Scenario: Doing a frequency search for words with apostrophes (what's)
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Frequency search |
    And the item list "Frequency search" has items hcsvlab:5
    And I am on the item list page for "Frequency search"
    And the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    When I select "Collection" from "Facet"
    When I fill in "Frequency search for" with "what's"
    And I press "execute_frequency_search"
    Then frequency search for "what's" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | auslit     | 1                 | 1         | 10              | 89728      |

  Scenario: Doing an empty frequency search
    And "researcher@intersect.org.au" has item lists
      | name       |
      | Frequency search |
    And the item list "Frequency search" has items hcsvlab:5
    And I am on the item list page for "Frequency search"
    And the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    When I select "Collection" from "Facet"
    When I fill in "Frequency search for" with ""
    And I press "execute_frequency_search"
    Then frequency search for "" in item list "Frequency search" should show error