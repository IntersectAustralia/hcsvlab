@ingest_qa_collections
Feature: Searching for items
  As a Researcher,
  I want to search for items
  So that I can add them to my item lists
# Don't need to test Blacklight comprehensively
# Just test any extensions to Blacklight we have made

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
  Scenario: Search returns correct results
    When I have done a search with collection "austlit"
    Then I should see "blacklight_results" table with
      | Identifier          | Type(s)             |
      | austlit:adaessa.xml | Text, Original, Raw |
      | austlit:bolroma.xml | Text, Original, Raw |

  Scenario: Must be logged in to see search history
    Given I follow "researcher@intersect.org.au"
    And I follow "Logout"
    And I am on the search history page
    Then I should see "Please enter your email and password to log in"

  @javascript
  Scenario: Search for simple term in all metadata
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "monologue"
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |
      | ice:S2B-035         | The Money or the Gun 	        | 3/5/94       | Text                |

  @javascript
  Scenario: Search for two simple term in all metadata joined with AND
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "University AND Romance"
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |
      | austlit:bolroma.xml | A Romance of Canvas Town 	    | 1898 	       | Text, Original, Raw |

  @javascript
  Scenario: Search for two simple term in all metadata joined with OR
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "University OR Romance"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Title                         | Created Date | Type(s)             |
      | austlit:adaessa.xml | Australian Essays             | 1886 	       | Text, Original, Raw |
      | austlit:bolroma.xml | A Romance of Canvas Town      | 1898 	       | Text, Original, Raw |

  @javascript
  Scenario: Search for term with tilde in all metadata
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "Univarsoty~"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Title                         | Created Date | Type(s)             |
      | custom:utf8_test_1  | UTF-8 Test item               | 1986         | Text                |
      | austlit:adaessa.xml | Australian Essays             | 1886 	       | Text, Original, Raw |
      | austlit:bolroma.xml | A Romance of Canvas Town 	    | 1898 	       | Text, Original, Raw |

  @javascript
  Scenario: Search for term with asterisk in all metadata
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "Correspon*"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term with asterisk in all metadata and simple term in full_text
    When I fill in "q" with "can"
    And I expand the facet Search Metadata
    And I fill in "Metadata" with "Correspon*"
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |

  @javascript
  Scenario: Search for term with field:value in all metadata using solr field name
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "AUSNC_discourse_type_tesim:letter"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term with field:value in all metadata using user friendly field name
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "discourse_type:letter"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term with field:value in all metadata using user friendly and solr field name
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "discourse_type:letter AND COOEE_texttype_tesim:Private*"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term with field:value in all metadata using user friendly field name and all metadata search
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "Correspondence AND discourse_type:letter"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term with field:value in all metadata using user friendly field name and all metadata search with asterisk
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "Correspon* AND discourse_type:letter"
    And I press "search_metadata"
    Then I should see a table with the following rows in any order:
      | Identifier          | Created Date | Type(s)             |
      | cooee:1-001         | 10/11/1791   | Text, Original, Raw |
      | cooee:1-002         | 10/11/1791   | Text                |

  @javascript
  Scenario: Search for term using quotes in all metadata
    #We need to repopulate the fields name mappings
    Given I reindex all
    When I expand the facet Search Metadata
    And I fill in "Metadata" with:
    """
    date_group_facet:"1880 - 1889"
    """
    And I press "search_metadata"
    And I wait 3 seconds
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date | Type(s)             |
      | austlit:adaessa.xml | 1886         | Text, Original, Raw |

  @javascript
  Scenario: Search for term using ranges in all metadata
    When I expand the facet Search Metadata
    And I fill in "Metadata" with "[1810 TO 1899]"
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |
      | austlit:adaessa.xml | Australian Essays             | 1886         | Text, Original, Raw |
      | austlit:bolroma.xml | A Romance of Canvas Town      | 1898         | Text, Original, Raw |

  @javascript
  Scenario: The metadata search should not search the full text
    When I expand the facet Search Metadata
    And I fill in "Metadata" with:
    """
    "Francis Adams"
    """
    And I press "search_metadata"
    #And pause
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |
      | austlit:adaessa.xml | Australian Essays             | 1886         | Text, Original, Raw |
    Then I expand the facet Search Metadata
    And I fill in "Metadata" with ""
    And I fill in "q" with:
    """
    "Francis Adams"
    """
    And I press "search_metadata"
    Then I should see "blacklight_results" table with
      | Identifier          | Title                         | Created Date | Type(s)             |

  @javascript
  Scenario: The searchable fields should be displayed
    Given I reindex all
    Given I am on the searchable fields page
    Then I should see a table with the following rows in any order:
      | RDF Name  | User Name   |
      | rdf:type  | RDF_type    |
      | dc:type   | type        |

  @javascript
  Scenario: Search using armenian small letter ZHE UTF-8 character in full_text
    When I fill in "q" with "ժ"
    And I press "search"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date  | Type(s)     |
      | custom:utf8_test_1  | 1986          | Text        |

  @javascript
  Scenario: Search using latin capital letter R UTF-8 character in full_text
    When I fill in "q" with "Ȓ"
    And I press "search"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date  | Type(s)     |
      | custom:utf8_test_1  | 1986          | Text        |

  @javascript
  Scenario: Search using arabic letter farsi yeh with inverted V UTF-8 character in full_text
    When I fill in "q" with "ؽ"
    And I press "search"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date  | Type(s)     |
      | custom:utf8_test_1  | 1986          | Text        |

  @javascript
  Scenario: Search using devanagari letter La UTF-8 character in full_text
    When I fill in "q" with "ल"
    And I press "search"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date  | Type(s)     |
      | custom:utf8_test_1  | 1986          | Text        |

  @javascript
  Scenario: Search using greek small letter Theta UTF-8 character in full_text
    When I fill in "q" with "θ"
    And I press "search"
    Then I should see "blacklight_results" table with
      | Identifier          | Created Date  | Type(s)     |
      | custom:utf8_test_1  | 1986          | Text        |
