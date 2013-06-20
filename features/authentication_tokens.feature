Feature: Create and manage authentication tokens
  In order to use the system via an API
  As a user
  I want to manage my authentication token

  Background:
    Given I have the usual roles and permissions
    And I have a user "diego@intersect.org.au" with role "researcher"
    And I am logged in as "diego@intersect.org.au"

  Scenario: New user has no token
    Then I should see no api token

  Scenario: Generate a token
    When I follow "Generate Token"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    And I should not see link "Generate Token"
    And I should see link "Regenerate Token"

  @javascript
  Scenario: Regenerate a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    And I click "diego@intersect.org.au"
    And I hover over "Authorisation Token"
    And I follow "Regenerate Token"
    Then The popup text should contain "Are you sure you want to regenerate your token? You will need to update any scripts that used the previous token."
    When I confirm the popup
    And I click "diego@intersect.org.au"
    And I hover over "Authorisation Token"    
    Then I should see the api token displayed for user "diego@intersect.org.au"

  @javascript
  Scenario: Delete a token
    Given "diego@intersect.org.au" has an api token
    And I am on the home page
    And I click "diego@intersect.org.au"
    And I hover over "Authorisation Token"
    And I follow "Delete Token"
    Then The popup text should contain "Are you sure you want to delete your token? You will no longer be able to perform API actions."
    When I confirm the popup
    And I click "diego@intersect.org.au"
    And I hover over "Authorisation Token"
    Then I should see no api token

  Scenario: Tokens can't be used on non-API actions
    And I follow "Generate Token"
    Then I should see the api token displayed for user "diego@intersect.org.au"
    When I make a request for the item lists page with the API token for "diego@intersect.org.au"
    Then I should get a 401 response code

