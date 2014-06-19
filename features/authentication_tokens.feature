Feature: Create and manage authentication tokens
  In order to use the system via an API
  As a user
  I want to manage my authentication token

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                  | first_name | last_name |
      | diego@intersect.org.au | Diego      | Alonso    |
    And "diego@intersect.org.au" has role "researcher"
    And I am logged in as "diego@intersect.org.au"

  Scenario: New user has no token
    Then I should see no api token

  Scenario: Generate a token
    When I follow "Generate API Key"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I should not see link "Generate API Key"
    And I should see link "Regenerate API Key"

  Scenario: Regenerate a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Regenerate API Key"
    Then I should see the api token displayed for user "diego@intersect.org.au"

  Scenario: Delete a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Delete API Key"
    Then I should see no api token

  Scenario: Tokens can't be used on non-API actions
    And I follow "Generate API Key"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Logout"
    When I make a JSON request for the catalog page with the API token for "diego@intersect.org.au"
    Then I should get a 406 response code

  Scenario: Download a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Download API Key"
    Then I should get the API config file for "diego@intersect.org.au"

  Scenario: Download a token while timed out
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I am logged out
    And I am on the download api key page
    And I should see "You need to log in before continuing."

  Scenario: Generate a token while timed out
    And I am on the home page
    Then I should see no api token
    And I am logged out
    And I am on the generate api key page
    And I should see "You need to log in before continuing."

  Scenario: Regenerate a token while timed out
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I am logged out
    And I am on the generate api key page
    And I should see "You need to log in before continuing."


