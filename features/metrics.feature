Feature: Administer users
  In order to allow users to access the system
  As an administrator
  I want to administer users

  Background:
    Given I have users
      | email                       | first_name | last_name |
      | raul@intersect.org.au       | Raul       | Carrizo   |
      | georgina@intersect.org.au   | Georgina   | Edwards   |
      | data_owner@intersect.org.au | Data       | Owner     |
    And I have the usual roles and permissions
    And "georgina@intersect.org.au" has role "admin"
    And "data_owner@intersect.org.au" has role "data owner"

  Scenario: Count of total researcher visits and weekly frequency is shown on user list page
    And I am logged in as "georgina@intersect.org.au"
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
    And I am logged in as "georgina@intersect.org.au"
    Given I am on the list users page
    Then I should see "There are 0 registered users with role 'researcher'."
    And I should see "Total number of visits by users with role 'researcher' in the last week is 0."
    And I should see "Total duration of use by users with role 'researcher' in the last week is 0 hours"
    And I should see "Average frequency of use per week by users with role 'researcher' is 0 total number of visits."
    And I should see "Average duration of use per week by users with role 'researcher' is 0 hours per user"

  Scenario Outline: View metrics table
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
    And I am logged in as "<email>"
    And I click "View Usage Metrics"
    Then I should be on the view metrics page
    And I should see "Usage Metrics"
    And I should see "metrics" table with
      | Metric                                                          | Value        |
      | Number of registered users with role 'researcher'               | 2            |
      | Total duration of use by users with role 'researcher' (minutes) | <duration>   |
      | Total number of API calls                                       | 3            |
      | Total number of item list API calls                             | 1            |
      | Total number of item lists created                              | 2            |
      | Total number of searches made                                   | 3            |
      | Total number of triplestore searches made                       | 1            |
      | Total number of uploaded annotation sets                        | 0            |
      | Total number of visits by users with role 'researcher'          | <num_visits> |
  Examples:
    | email                        | duration | num_visits |
    | georgina@intersect.org.au    | 50.0     | 3          |
    | data_owner@intersect.org.au  | 50.0     | 3          |
    | researcher1@intersect.org.au | 80.0     | 4          |
    | researcher2@intersect.org.au | 80.0     | 4          |

  Scenario Outline: Download metrics CSV
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
    And I am logged in as "<email>"
    And I click "View Usage Metrics"
    And I click "Download all weeks as CSV"
    Then I should get a CSV file called "metrics.csv" with the following metrics:
    """
    metric,week_ending,value,cumulative_value
    Number of registered users with role 'researcher'
    2,2
    Total number of visits by users with role 'researcher'
    1,1
    2,3
    <num_visits>
    Total number of searches made
    1,1
    3,4
    Total number of triplestore searches made
    1,1
    Total duration of use by users with role 'researcher' (minutes)
    60.0,60.0
    60.0,120.0
    <duration>
    Total number of item lists created
    2,2
    Total number of uploaded annotation sets
    1,1
    Total number of API calls
    1,1
    <api_calls>
    Total number of item list API calls
    1,1
    """
  Examples:
    | email                        | num_visits | duration   | api_calls |
    | georgina@intersect.org.au    | 3,4        | 50.0,170.0 | 3,4       |
    | data_owner@intersect.org.au  | 3,4        | 50.0,170.0 | 3,4       |
    | researcher1@intersect.org.au | 4,7        | 80.0,200.0 | 4,5       |
    | researcher2@intersect.org.au | 4,7        | 80.0,200.0 | 4,5       |