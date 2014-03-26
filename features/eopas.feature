Feature: Displaying Items in EOPAS
  As a Researcher,
  I want to view audio and video in EOPAS if I have a correct transcript and a media file

  Background:
    Given I have the usual roles and permissions
    Given I have users
      | email                       | first_name | last_name |
      | researcher@intersect.org.au | Researcher | One       |
    And "researcher@intersect.org.au" has role "researcher"
    And I am logged in as "researcher@intersect.org.au"
    

  Scenario: View Audio in EOPAS
    Given I ingest "eopas_test:Audio_Eopas"
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | eopas_test      | read        |
    And I am on the catalog page
    And I should see "eopas_test"
    And I follow "eopas_test"
    And I should see "eopas_test:Audio_Eopas"
    And I follow "eopas_test:Audio_Eopas"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see "Audio_Eopas_audio.ogg"
    And I should see "Audio_Eopas_transcript.xml"
    And I should see fields displayed
      | field                                     | value                                 |
      | Collection                                | eopas_test                            |
      | Created                                   | 1998-10-03                            |
      | Mode                                      | unspecified                           |
      | Speech Style                              | unspecified                           |
      | Interactivity                             | unspecified                           |
      | Communication Context                     | unspecified                           |
      | Discourse Type                            | unspecified                           |
      | Language (ISO 639-3 Code)                 | bis, erk                              |
      | Audience                                  | unspecified                           |
      | Type                                      | Audio, Other                          |
    And I should see "View in EOPAS"  
    And I follow "View in EOPAS"
    And I should see "Media Player"
    And I should see "Back to Item Details"
    And I follow "Back to Item Details"
    And I follow "Audio_Eopas_transcript.xml"
    And I should see "Natopu nen kin ito esan ga"

  Scenario: View Video in EOPAS
    Given I ingest "eopas_test:Video_Eopas"
    Given I have user "researcher@intersect.org.au" with the following groups
      | collectionName  | accessType  |
      | eopas_test      | read        |
    And I am on the catalog page
    And I should see "eopas_test"
    And I follow "eopas_test"
    And I should see "eopas_test:Video_Eopas"
    And I follow "eopas_test:Video_Eopas"
    And I should see "Primary Document"
    And I should see "Documents"
    And I should see "Video_Eopas_video.ogg"
    And I should see "Video_Eopas_transcript.xml"
    And I should see fields displayed
      | field                                     | value                                 |
      | Collection                                | eopas_test                            |
      | Mode                                      | unspecified                           |
      | Speech Style                              | unspecified                           |
      | Interactivity                             | unspecified                           |
      | Communication Context                     | unspecified                           |
      | Discourse Type                            | unspecified                           |
      | Language (ISO 639-3 Code)                 | erk                                   |
      | Audience                                  | unspecified                           |
      | Type                                      | Other, Audio                          |
    And I should see "View in EOPAS"    
    And I follow "View in EOPAS"
    And I should see "Media Player"
    And I follow "Back to Item Details"
    And I follow "Video_Eopas_transcript.xml"
    And I should see "Ipitlak nai iskei ito Ertap"


  Scenario: Requesting an EOPAS item that doesn't exists
    Given I am on the eopas page for item "hcsvlab:notExists"
    Then I should see "Sorry, you have requested a record that doesn't exist."
