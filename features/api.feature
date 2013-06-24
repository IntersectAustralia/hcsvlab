Feature: Browsing via API
  As a Researcher,
  I want to use the API to get metadata relating to a particular Item.

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                  | first_name | last_name |
      | diego@intersect.org.au | Diego      | Alonso    |
    And "diego@intersect.org.au" has role "researcher"
    And "diego@intersect.org.au" has an api token
    And "diego@intersect.org.au" has item lists
      | name   |
      | Test 1 |
      | Test 2 |

  Scenario Outline: Visit pages with an API token and HTML format doesn't authenticate
    When I make a request for <page> with the API token for "diego@intersect.org.au"
    Then I should get a <code> response code
  Examples:
    | page                           | code |
    | the item lists page            | 302  |
    | the item lists page for Test 1 | 302  |
    | the home page                  | 200  |

  Scenario Outline: Visit pages with an API token and JSON format
    When I make a JSON request for <page> with the API token for "diego@intersect.org.au"
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                           | code |
    | the item lists page            | 200  |
    | the item lists page for Test 1 | 200  |
    | the home page                  | 406  |

  Scenario Outline: Visit pages without an API token and JSON format
    When I make a JSON request for <page> without an API token
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                           | code |
    | the item lists page            | 401  |
    | the item lists page for Test 1 | 401  |
    | the home page                  | 406  |

  Scenario Outline: Visit pages with an invalid API token and JSON format
    When I make a JSON request for <page> with an invalid API token
    Then I should get a <code> response code
  # home page does not accept json response
  Examples:
    | page                           | code |
    | the item lists page            | 401  |
    | the item lists page for Test 1 | 401  |
    | the home page                  | 406  |

  Scenario: Get item lists for researcher
    When I make a JSON request for the item lists page with the API token for "diego@intersect.org.au"
    Then I should get a 200 response code
    And I should get a JSON response with
      | name   | num_items |
      | Test 1 | 0         |
      | Test 2 | 0         |


