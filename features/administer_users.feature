Feature: Administer users
  In order to allow users to access the system
  As an administrator
  I want to administer users

  Background:
    Given I have users
      | email                     | first_name | last_name |
      | raul@intersect.org.au     | Raul       | Carrizo   |
      | georgina@intersect.org.au | Georgina   | Edwards   |
    And I have the usual roles and permissions
    And I am logged in as "georgina@intersect.org.au"
    And "georgina@intersect.org.au" has role "admin"

  Scenario: View a list of users
    Given "raul@intersect.org.au" is deactivated
    When I am on the list users page
    Then I should see "users" table with
      | First name | Last name | Email                     | Role  | Status      |
      | Georgina   | Edwards   | georgina@intersect.org.au | admin | Active      |
      | Raul       | Carrizo   | raul@intersect.org.au     |       | Deactivated |

  Scenario: View user details
    Given "raul@intersect.org.au" has role "researcher"
    And I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    Then I should see field "Email" with value "raul@intersect.org.au"
    And I should see field "First Name" with value "Raul"
    And I should see field "Last Name" with value "Carrizo"
    And I should see field "Role" with value "researcher"
    And I should see field "Status" with value "Active"

  Scenario: Go back from user details
    Given I am on the list users page
    When I follow "View Details" for "georgina@intersect.org.au"
    And I follow "Back"
    Then I should be on the list users page

  Scenario: Edit role
    Given "raul@intersect.org.au" has role "researcher"
    And I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    And I follow "Edit role"
    And I select "admin" from "Role"
    And I press "Save"
    Then I should be on the user details page for raul@intersect.org.au
    And I should see "The role for raul@intersect.org.au was successfully updated."
    And I should see field "Role" with value "admin"

  Scenario: Edit role from list page
    Given "raul@intersect.org.au" has role "researcher"
    And I am on the list users page
    When I follow "Edit role" for "raul@intersect.org.au"
    And I select "data owner" from "Role"
    And I press "Save"
    Then I should be on the user details page for raul@intersect.org.au
    And I should see "The role for raul@intersect.org.au was successfully updated."
    And I should see field "Role" with value "data owner"

  Scenario: Cancel out of editing roles
    Given "raul@intersect.org.au" has role "researcher"
    And I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    And I follow "Edit role"
    And I select "admin" from "Role"
    And I follow "Back"
    Then I should be on the user details page for raul@intersect.org.au
    And I should see field "Role" with value "researcher"

  Scenario: Role should be mandatory when editing Role
    And I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    And I follow "Edit role"
    And I select "" from "Role"
    And I press "Save"
    Then I should see "Please select a role for the user."

  Scenario: Deactivate active user
    Given I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    And I follow "Deactivate"
    Then I should see "The user has been deactivated"
    And I should see "Activate"

  Scenario: Activate deactivated user
    Given "raul@intersect.org.au" is deactivated
    And I am on the list users page
    When I follow "View Details" for "raul@intersect.org.au"
    And I follow "Activate"
    Then I should see "The user has been activated"
    And I should see "Deactivate"

  Scenario: Can't deactivate the last administrator account
    Given I am on the list users page
    When I follow "View Details" for "georgina@intersect.org.au"
    And I follow "Deactivate"
    Then I should see "You cannot deactivate this account as it is the only account with admin privileges."
    And I should see field "Status" with value "Active"

  Scenario: Editing own role has alert
    Given I am on the list users page
    When I follow "View Details" for "georgina@intersect.org.au"
    And I follow "Edit role"
    Then I should see "You are changing the role of the user you are logged in as."

  Scenario: Should not be able to edit role of rejected user by direct URL entry
    Given I have a rejected as spam user "spam@intersect.org.au"
    And I go to the edit role page for spam@intersect.org.au
    Then I should be on the list users page
    And I should see "Role can not be set. This user has previously been rejected as a spammer."

  Scenario: Count of users with role 'researcher' is shown on user list page
    Given I have 4 active users with role "researcher"
    And I have 2 deactivated users with role "researcher"
    And I have 3 active users with role "admin"
    When I am on the list users page
    Then I should see "There are 4 registered users with role 'researcher'."

  Scenario: I must be logged in to administer users
    Given I follow "georgina@intersect.org.au"
    And I follow "Logout"
    And I am on the admin page
    Then I should see "Please enter your email and password to log in"

  Scenario: Count of total researcher visits and weekly frequency is shown on user list page
    Given I have users
      | email                        | first_name | last_name |
      | researcher1@intersect.org.au | Researcher | One       |
      | researcher2@intersect.org.au | Researcher | Two       |
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher2@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 3_DAYS_AGO   | 10                  |
      | 4_DAYS_AGO   | 30                  |
      | 8_DAYS_AGO   | 60                  |
      | 10_DAYS_AGO  | 5                   |
      | 15_DAYS_AGO  | 40                  |
      | 16_DAYS_AGO  | 20                  |
    And "researcher2@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 2_DAYS_AGO   | 30                  |
      | 3_DAYS_AGO   | 10                  |
      | 4_DAYS_AGO   | 30                  |
      | 5_DAYS_AGO   | 120                 |
      | 6_DAYS_AGO   | 60                  |
    And I am on the list users page
    Then I should see "Total number of visits by users with role 'researcher' in the last week is 7."
    And I should see "Total duration of use by users with role 'researcher' in the last week is 4.83 hours"
    And I should see "Average frequency of use per week by users with role 'researcher' is 3.67 total number of visits."
    And I should see "Average duration of use per week by users with role 'researcher' is 2.31 hours per user"

  Scenario: Counts when there are no researchers/visits is shown on the user list page
    Given I am on the list users page
    Then I should see "There are 0 registered users with role 'researcher'."
    And I should see "Total number of visits by users with role 'researcher' in the last week is 0."
    And I should see "Total duration of use by users with role 'researcher' in the last week is 0 hours"
    And I should see "Average frequency of use per week by users with role 'researcher' is 0 total number of visits."
    And I should see "Average duration of use per week by users with role 'researcher' is 0 hours per user"

  Scenario: View metrics table
    Given I am on the admin page
    And I have users
      | email                        | first_name | last_name |
      | researcher1@intersect.org.au | Researcher | One       |
      | researcher2@intersect.org.au | Researcher | Two       |
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher2@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 0_DAYS_AGO   | 10                  |
      | 7_DAYS_AGO   | 30                  |
      | 14_DAYS_AGO  | 60                  |
    And "researcher1@intersect.org.au" has the following past searches
      | search_time | type        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | triplestore |
      | 14_DAYS_AGO | main        |
    And "researcher2@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 0_DAYS_AGO   | 30                  |
      | 0_DAYS_AGO   | 10                  |
      | 7_DAYS_AGO   | 30                  |
    And "researcher1@intersect.org.au" has the following past api calls
      | request_time | item_list |
      | 0_DAYS_AGO   | true      |
      | 0_DAYS_AGO   | false     |
      | 14_DAYS_AGO  | false     |
    And "georgina@intersect.org.au" has an api token
    And I make a JSON request for the annotation context page with the API token for "georgina@intersect.org.au"
    And "researcher1@intersect.org.au" has item lists
      | name  |
      | Test  |
      | Test2 |
    And I click "View Metrics"
    Then I should be on the view metrics page
    And I should see "Metrics"
    And I should see "metrics" table with
      | Metric                                                          | Value |
      | Number of registered users with role 'researcher'               | 2     |
      | Total duration of use by users with role 'researcher' (minutes) | 50.0  |
      | Total number of API calls                                       | 3     |
      | Total number of item list API calls                             | 1     |
      | Total number of item lists created                              | 2     |
      | Total number of searches made                                   | 3     |
      | Total number of triplestore searches made                       | 1     |
      | Total number of uploaded annotation sets                        | 0     |
      | Total number of visits by users with role 'researcher'          | 3     |

  Scenario: Download metrics CSV
    Given I am on the admin page
    And I have users
      | email                        | first_name | last_name |
      | researcher1@intersect.org.au | Researcher | One       |
      | researcher2@intersect.org.au | Researcher | Two       |
    And "researcher1@intersect.org.au" has role "researcher"
    And "researcher2@intersect.org.au" has role "researcher"
    And "researcher1@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 0_DAYS_AGO   | 10                  |
      | 7_DAYS_AGO   | 30                  |
      | 14_DAYS_AGO  | 60                  |
    And "researcher1@intersect.org.au" has the following past searches
      | search_time | type        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | main        |
      | 0_DAYS_AGO  | triplestore |
      | 14_DAYS_AGO | main        |
    And "researcher2@intersect.org.au" has the following past sessions
      | sign_in_time | duration_in_minutes |
      | 0_DAYS_AGO   | 30                  |
      | 0_DAYS_AGO   | 10                  |
      | 7_DAYS_AGO   | 30                  |
    And "researcher1@intersect.org.au" has the following past api calls
      | request_time | item_list |
      | 0_DAYS_AGO   | true      |
      | 0_DAYS_AGO   | false     |
      | 14_DAYS_AGO  | false     |
    And "georgina@intersect.org.au" has an api token
    And I make a JSON request for the annotation context page with the API token for "georgina@intersect.org.au"
    And "researcher1@intersect.org.au" has item lists
      | name  |
      | Test  |
      | Test2 |
    And I ingest "cooee:1-001"
    And "georgina@intersect.org.au" has "read" access to collection "cooee"
    And "georgina@intersect.org.au" has an api token
    And I make a JSON multipart request for the catalog annotations page for "cooee:1-001" with the API token for "georgina@intersect.org.au" with JSON params
      | Name | Content | Filename                                               | Type                     |
      | file |         | test/samples/annotations/upload_annotation_sample.json | application/octet-stream |
    And I click "View Metrics"
    And I click "Download all weeks as CSV"
    Then I should get a CSV file called "metrics.csv" with the following metrics:
    """
    metric,week_ending,value,cumulative_value
    Number of registered users with role 'researcher'
    2,2
    Total number of visits by users with role 'researcher'
    1,1
    2,3
    3,6
    Total number of searches made
    1,1
    3,4
    Total number of triplestore searches made
    1,1
    Total duration of use by users with role 'researcher' (minutes)
    60.0,60.0
    60.0,120.0
    50.0,170.0
    Total number of item lists created
    2,2
    Total number of uploaded annotation sets
    1,1
    Total number of API calls
    1,1
    3,4
    Total number of item list API calls
    1,1
    """