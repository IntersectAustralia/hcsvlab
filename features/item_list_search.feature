@javascript
Feature: Searching item lists
  As a Researcher,
  I want to search my item lists
  So that I can analyse my collection

  Background:
    Given I ingest "cooee:1-001"
    Given I ingest "auslit:adaessa"
    Given I ingest "auslit:bolroma"
    Given I have the usual roles and permissions
    Given I have users
      | email                        | first_name | last_name |
      | researcher@intersect.org.au  | Researcher | One       |
      | researcher2@intersect.org.au | Researcher | two       |
    Given "researcher@intersect.org.au" has role "researcher"
    Given "researcher2@intersect.org.au" has role "researcher"
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |

  ##########################################################################
  ## CONCORDANCE SEARCH                                                   ##
  ##########################################################################

  Scenario: Doing a concordance search for "family"
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name               |
      | Concordance search |
    Given the item list "Concordance search" has items cooee:1-001
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 1 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "family"
    And I press "execute_concordance_search"
    Then concordance search for "family" in item list "Concordance search" should show this results
      | documentTitle | textBefore                   | textHighlighted | textAfter                       |
      | cooee:1-001   | Banks & to the Ladys of your | family          | .The hurry in which I write you |

  Scenario: Doing a concordance search for "make"
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name               |
      | Concordance search |
    Given the item list "Concordance search" has items cooee:1-001
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 1 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "make"
    And I press "execute_concordance_search"
    Then concordance search for "make" in item list "Concordance search" should show this results
      | documentTitle | textBefore                        | textHighlighted | textAfter                                 |
      | cooee:1-001   | get the small fish, of which they | make            | no account in the Summer nor can          |
      | cooee:1-001   | will, Sir, be so obliging as to   | make            | my Compliments acceptable to Lady Banks & |

  Scenario: Doing a concordance search for "concordance"
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name               |
      | Concordance search |
    Given the item list "Concordance search" has items cooee:1-001, austlit:adaessa
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "concordance"
    And I press "execute_concordance_search"
    Then concordance search for "concordance" in item list "Concordance search" should show not matches found message

  Scenario: Doing a failing concordance search for "dog-"
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name               |
      | Concordance search |
    Given the item list "Concordance search" has items cooee:1-001, austlit:adaessa
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "dog-"
    And I press "execute_concordance_search"
    Then concordance search for "dog-" in item list "Concordance search" should show error

  Scenario: Doing a failing concordance search for "dog like"
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name               |
      | Concordance search |
    Given the item list "Concordance search" has items cooee:1-001, austlit:adaessa
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "dog-"
    And I press "execute_concordance_search"
    Then concordance search for "dog like" in item list "Concordance search" should show error

  ##########################################################################
  ## CONCORDANCE SEARCH IN SHARED ITEM LISTS                              ##
  ##########################################################################

  Scenario: Doing a concordance search for "family" in shared item list with access to only 1 item in the item list
    Given "researcher@intersect.org.au" has item lists
      | name               | shared |
      | Concordance search | true   |
    Given I have user "researcher2@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    Given the item list "Concordance search" has items cooee:1-001
    Given I am logged in as "researcher2@intersect.org.au"
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 1 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "family"
    And I press "execute_concordance_search"
    Then concordance search for "family" in item list "Concordance search" should show this results
      | documentTitle | textBefore                   | textHighlighted | textAfter                       |
      | cooee:1-001   | Banks & to the Ladys of your | family          | .The hurry in which I write you |

  Scenario: Doing a concordance search for "family" in shared item list without access to items in the item list
    Given "researcher@intersect.org.au" has item lists
      | name               | shared |
      | Concordance search | true   |
    Given the item list "Concordance search" has items cooee:1-001, austlit:adaessa
    Given I am logged in as "researcher2@intersect.org.au"
    Given I am on the item list page for "Concordance search"
    Then the item list "Concordance search" should have 2 items
    When I select "Concordance" from "search_type"
    And I fill in "Concordance search for" with "family"
    And I press "execute_concordance_search"
    Then concordance search for "concordance" in item list "Concordance search" should show not matches found message

  ##########################################################################
  ## FREQUENCY SEARCH                                                     ##
  ##########################################################################

  Scenario: Doing a frequency search for simple words (can)
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name             |
      | Frequency search |
    Given the item list "Frequency search" has items austlit:bolroma
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    And I select "Collection" from "Facet"
    And I fill in "Frequency search for" with "can"
    And I press "execute_frequency_search"
    Then frequency search for "can" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | austlit    | 1                 | 1         | 182             | 89728      |

  Scenario: Doing a frequency search for words word (what)
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name             |
      | Frequency search |
    Given the item list "Frequency search" has items austlit:bolroma
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    And I select "Created" from "Facet"
    And I fill in "Frequency search for" with "what"
    And I press "execute_frequency_search"
    Then frequency search for "what" in item list "Frequency search" should show this results
      | facetValue  | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | 1890 - 1899 | 1                 | 1         | 229             | 89728      |

  Scenario: Doing a frequency search for words with apostrophes (what's)
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name             |
      | Frequency search |
    Given the item list "Frequency search" has items austlit:bolroma
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    And I select "Collection" from "Facet"
    And I fill in "Frequency search for" with "what's"
    And I press "execute_frequency_search"
    Then frequency search for "what's" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | austlit    | 1                 | 1         | 10              | 89728      |

  Scenario: Doing an empty frequency search
    Given I am logged in as "researcher@intersect.org.au"
    Given "researcher@intersect.org.au" has item lists
      | name             |
      | Frequency search |
    Given the item list "Frequency search" has items austlit:bolroma
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 1 items
    When I select "Frequency" from "search_type"
    And I select "Collection" from "Facet"
    And I fill in "Frequency search for" with ""
    And I press "execute_frequency_search"
    Then frequency search for "" in item list "Frequency search" should show error

  ##########################################################################
  ## FREQUENCY SEARCH IN SHARED ITEM LISTS                                ##
  ##########################################################################

  Scenario: Doing a frequency search for simple words (can) in a shared item list with access to all the items in the item list
    Given "researcher@intersect.org.au" has item lists
      | name             | shared |
      | Frequency search | true   |
    Given the item list "Frequency search" has items cooee:1-001, austlit:bolroma
    Given I have user "researcher2@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
      | austlit        | read       |
    Given I am logged in as "researcher2@intersect.org.au"
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 2 items
    When I select "Frequency" from "search_type"
    And I select "Collection" from "Facet"
    And I fill in "Frequency search for" with "can"
    And I press "execute_frequency_search"
    Then frequency search for "can" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | austlit    | 1                 | 1         | 182             | 89728      |
      | cooee      | 1                 | 1         | 2               | 924        |

  Scenario: Doing a frequency search for simple words (can) in a shared item list with access to 1 of the items in the item list
    Given "researcher@intersect.org.au" has item lists
      | name             | shared |
      | Frequency search | true   |
    Given the item list "Frequency search" has items cooee:1-001, austlit:bolroma
    Given I have user "researcher2@intersect.org.au" with the following groups
      | collectionName | accessType |
      | cooee          | read       |
    Given I am logged in as "researcher2@intersect.org.au"
    Given I am on the item list page for "Frequency search"
    Then the item list "Frequency search" should have 2 items
    When I select "Frequency" from "search_type"
    And I select "Collection" from "Facet"
    And I fill in "Frequency search for" with "can"
    And I press "execute_frequency_search"
    Then frequency search for "can" in item list "Frequency search" should show this results
      | facetValue | matchingDocuments | totalDocs | termOccurrences | totalWords |
      | cooee      | 1                 | 1         | 2               | 924        |
