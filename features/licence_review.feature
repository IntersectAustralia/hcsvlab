Feature: Managing Subscriptions to Collections
  As a Data Owner, I want Researchers to be able to agree to the licence terms
  which I have set for my Collections and Collection Lists.

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name   | last_name |
      | data_owner@intersect.org.au | dataOwner    | One       |
      | researcher@intersect.org.au | Edmund       | Muir      |
    Given "data_owner@intersect.org.au" has role "data owner"
    Given "researcher@intersect.org.au" has role "researcher"
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given I ingest licences
    Given Collections ownership is
      | collection | ownerEmail                  |
      | cooee      | data_owner@intersect.org.au |
      | austlit    | data_owner@intersect.org.au |
    And User "data_owner@intersect.org.au" has a Collection List called "List_1" containing
      | collection |
      | cooee      |

  @javascript
  Scenario: Verifying that my Collections and Collection Lists with no licence do not appear on the Licence Agreements page
    Given I am logged in as "data_owner@intersect.org.au"
    And I am on the licence_agreements page
    Then I should see "There are no licensed collections or collection lists visible in the system"

  @javascript
  Scenario: Verifying that my Collections and Collection Lists with a licence do appear on the Licence Agreements page
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to Collection "austlit"
    And I have added a licence to Collection List "List_1"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state | actions |
      | List_1  | 1          | data_owner@intersect.org.au | Owner |         |
      | austlit | 1          | data_owner@intersect.org.au | Owner |         |

  @javascript
  Scenario: Verifying that other users' Collections and Collection Lists with no licence do not appear on the Licence Agreements page
    Given I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then I should see "There are no licensed collections or collection lists visible in the system"

  @javascript
  Scenario: Verifying that other users; Collections and Collection Lists with a licence do appear on the Licence Agreements page
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to Collection "austlit"
    And I have added a licence to Collection List "List_1"
    And I follow "data_owner@intersect.org.au"
    And I follow "Logout"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
      | austlit | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |

  @javascript
  Scenario: Verifying that other users; Private Collections and Private Collection Lists with a licence do appear on the Licence Agreements page
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to private Collection "austlit"
    And I have added a licence to private Collection List "List_1"
    And I follow "data_owner@intersect.org.au"
    And I follow "Logout"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions        |
      | List_1  | 1          | data_owner@intersect.org.au | Unapproved   | Request Access |
      | austlit | 1          | data_owner@intersect.org.au | Unapproved   | Request Access |

  @javascript
  Scenario: Verifying that one can click through to the details of a collection
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to Collection "austlit"
    And I follow "data_owner@intersect.org.au"
    And I follow "Logout"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | austlit | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
    When I click the link in the 1st column of the 1st row of the "collections" table
    Then I should see "AustLit provides full-text access to hundreds of examples of out of copyright poetry, fiction and criticism ranging from 1795 to the 1930s"
    And I should see "Back to Licence Agreements"
    And I should see "Collection Details"
    When I click "Back to Licence Agreements"
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | austlit | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |

  @javascript
  Scenario: Verifying that one can show which collections are in a collection list and then click through to their details
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to Collection List "List_1"
    And I follow "data_owner@intersect.org.au"
    And I follow "Logout"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
    When I click the button in the 1st column of the 1st row of the "collections" table
    And I wait 2 seconds
    And Save a screenshot with name "log/list.png"
    And I click "cooee"
    And I wait 2 seconds
    And Save a screenshot with name "log/cooee.png"
    Then I should see "Corpus of Oz Early English"
    And I should see "Back to Licence Agreements"
    And I should see "Collection Details"
    When I click "Back to Licence Agreements"
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |

  @javascript
  Scenario: Verifying that I can sign up to licence agreements
    And I am logged in as "data_owner@intersect.org.au"
    And I have added a licence to Collection "austlit"
    And I have added a licence to Collection List "List_1"
    And I follow "data_owner@intersect.org.au"
    And I follow "Logout"
    And I am logged in as "researcher@intersect.org.au"
    And I am on the licence_agreements page
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
      | austlit | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
    When I click the button in the 5th column of the 1st row of the "collections" table
    And I wait 2 seconds
#    And Save a screenshot with name "log/gg.png"
#    And Show Browser Inspector
    And I click "Close" on the 1st licence dialogue
#    And I wait 2 seconds
#    And Save a screenshot with name "log/gg2.png"
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
      | austlit | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
    When I click the button in the 5th column of the 2nd row of the "collections" table
    And I wait 2 seconds
    And I click "Accept" on the 2nd licence dialogue
    Then the Review and Acceptance of Licence Terms table should have
      | title   | collection | owner                       | state        | actions                        |
      | List_1  | 1          | data_owner@intersect.org.au | Not Accepted | Preview & Accept Licence Terms |
      | austlit | 1          | data_owner@intersect.org.au | Accepted     | Review Licence Terms           |
