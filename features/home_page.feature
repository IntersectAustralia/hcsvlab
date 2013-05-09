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
