Feature: Creating Collections
  As a Data Owner or Admin,
  I want to create a collection via the web app

  Background:
    Given I have the usual roles and permissions
    And I have a user "admin@intersect.org.au" with role "admin"
    And I have a user "data_owner@intersect.org.au" with role "data owner"
    And I have a user "researcher@intersect.org.au" with role "researcher"

  Scenario: Verify create collection button is visible for admin
    Given I am logged in as "admin@intersect.org.au"
    When I am on the catalog page
    Then I should see link "Create Collection" to "/catalog-create"

  Scenario: Verify create collection button is visible for data owner
    Given I am logged in as "data_owmer@intersect.org.au"
    When I am on the catalog page
    Then I should see link "Create Collection" to "/catalog-create"

  Scenario: Verify create collection button is not visible for researcher
    Given I am logged in as "researcher@intersect.org.au"
    When I am on the catalog page
    Then I should not see link "Create Collection" to "/catalog-create"
