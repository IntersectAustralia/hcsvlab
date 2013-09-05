Feature: Home page
  In order to meet our obligations
  As the system owner
  I want appropriate attribution text on the home page

  Background:
    Given I have the usual roles and permissions
    And I have a user "chrisk@intersect.org.au"
    And "chrisk@intersect.org.au" has role "hcsvlab-admin"

  Scenario: Text is shown when not logged in
    Given I am on the home page
    Then I should see "The University of Western Sydney is proud to be in partnership, and acknowledge funding from, the National eResearch Collaboration Tools and Resources (NeCTAR) project http://www.nectar.org.au to develop the HCS vLab."
    And I should see "NeCTAR is an Australian Government project conducted as part of the Super Science initiative and financed by the Education Investment Fund."

  Scenario: Text is shown when logged in
    Given I am logged in as "chrisk@intersect.org.au"
    Then I should see "The University of Western Sydney is proud to be in partnership, and acknowledge funding from, the National eResearch Collaboration Tools and Resources (NeCTAR) project http://www.nectar.org.au to develop the HCS vLab."
    And I should see "NeCTAR is an Australian Government project conducted as part of the Super Science initiative and financed by the Education Investment Fund."

  Scenario: Licences Agreement link should appear for users which do not have access to any collection
    Given I have users
      | email                       | first_name   | last_name |
      | data_owner@intersect.org.au | dataOwner    | One       |
      | researcher@intersect.org.au | Researcher   | R         |
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given Collections ownership is
      |collection | ownerEmail                    |
      |austlit    | data_owner@intersect.org.au  |
      |cooee      | data_owner@intersect.org.au  |
    Given I am logged in as "researcher@intersect.org.au"
    Given I am on the home page
    Then I should see "Welcome! To gain access to Collections, visit the Licence Agreements page."

  Scenario: Licences Agreement link should appear for users which have access to some collection
    Given I have users
      | email                       | first_name   | last_name |
      | data_owner@intersect.org.au | dataOwner    | One       |
      | researcher@intersect.org.au | Researcher   | R         |
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given Collections ownership is
      |collection | ownerEmail                    |
      |austlit    | data_owner@intersect.org.au  |
      |cooee      | data_owner@intersect.org.au  |
    Given "researcher@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "researcher@intersect.org.au"
    Given I am on the home page
    Then I should see "Welcome! To gain access to more Collections, visit the Licence Agreements page."

  Scenario: Licences Agreement link should not appear for users which have access to every collection
    Given I have users
      | email                       | first_name   | last_name |
      | data_owner@intersect.org.au | dataOwner    | One       |
      | researcher@intersect.org.au | Researcher   | R         |
    Given I ingest "cooee:1-001" with id "hcsvlab:1"
    Given I ingest "auslit:adaessa" with id "hcsvlab:2"
    Given Collections ownership is
      |collection | ownerEmail                    |
      |austlit    | data_owner@intersect.org.au  |
      |cooee      | data_owner@intersect.org.au  |
    Given "researcher@intersect.org.au" has "read" access to collection "austlit"
    Given "researcher@intersect.org.au" has "read" access to collection "cooee"
    Given I am logged in as "researcher@intersect.org.au"
    Given I am on the home page
    Then I should not see "Welcome! To gain access to Collections, visit the Licence Agreements page."
    And I should not see "Welcome! To gain access to more Collections, visit the Licence Agreements page."
