Feature: Accessing, assigning licences via API
  As a Data Owner,
  I want to use the API to get and assign licences to collections

  Background:
    Given I have the usual roles and permissions
    And I have users
      | email                        | first_name | last_name |
      | admin@intersect.org.au       | Admin      | One       |
      | researcher1@intersect.org.au | Researcher | One       |
      | data_owner@intersect.org.au  | Data_Owner | One       |
    And "admin@intersect.org.au" has role "admin"
    And "admin@intersect.org.au" has an api token
    And "data_owner@intersect.org.au" has role "data owner"
    And "data_owner@intersect.org.au" has an api token
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has an api token

  Scenario: Researcher can't access licences
    Given I make a JSON request for the licences page with the API token for "researcher1@intersect.org.au"
    Then I should get a 403 response code
    And the JSON response should be:
    """
    {"error":"You are not authorised to access this page."}
    """

  Scenario Outline: Data Owners and Admins can access licences via API
    Given I make a JSON request for the licences page with the API token for "<user>"
    Then I should get a 200 response code
  Examples:
    | user                        |
    | data_owner@intersect.org.au |
    | admin@intersect.org.au      |

  Scenario: No licences
    Given I make a JSON request for the licences page with the API token for "data_owner@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    []
    """

  Scenario: Get licences via API
    Given I have licence "Creative Commons" with id 100
    And I have licence "AusNC Terms of Use" with id 101
    And I make a JSON request for the licences page with the API token for "admin@intersect.org.au"
    Then I should get a 200 response code
    And the JSON response should be:
    """
    [{"name":"Creative Commons","id":100},{"name":"AusNC Terms of Use","id":101}]
    """