Feature: Create and manage authentication tokens
  In order to use the system via an API
  As a user
  I want to manage my authentication token

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                     | first_name | last_name |
      | diego@intersect.org.au    | Diego       | Alonso   |
    And "diego@intersect.org.au" has role "researcher"
    And I am logged in as "diego@intersect.org.au"

  Scenario: New user has no token
    Then I should see no api token

  Scenario: Generate a token
    When I follow "Generate Token"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I should not see link "Generate Token"
    And I should see link "Regenerate Token"

  Scenario: Regenerate a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Regenerate Token"
    Then I should see the api token displayed for user "diego@intersect.org.au"

  Scenario: Delete a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Delete Token"
    Then I should see no api token

  Scenario: Tokens can't be used on non-API actions
    And I follow "Generate Token"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    When I make a request for the item lists page with the API token for "diego@intersect.org.au"
    Then I should get a 401 response code

  Scenario: Download a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I follow "Download Token"
    Then I should get the authentication token json file for "diego@intersect.org.au"

