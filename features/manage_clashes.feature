Feature: Manage Clashes
  In order to participate in games
  As a user
  I would like to be able to manage which clashes I'm participating in

  Scenario: User creates a roshambo clash and then leaves
    Given I am signed in as test@email.com
    And there is a roshambo game
    When I try to create a roshambo clash
    Then I should see a clash creation form page
    When I fill in the roshambo information and try to create the clash
    Then there should be exactly 1 clash
    And there should be exactly 1 player list
    And test@email.com should be a player in that clash
    When I leave the clash
    Then there should be exactly 0 clashes
    
  Scenario: User creates a chess clash, switches sides, and then leaves
    Given I am signed in as test@email.com
    And there is a chess game
    When I try to create a chess clash
    Then I should see a clash creation form page
    When I fill in the chess information, choosing to start with white, and try to create the clash
    Then there should be exactly 1 clash
    And there should be exactly 2 player lists
    And test@email.com should be a player in the white list
    And test@email.com should not be a player in the black list
    When I become a black player for that clash
    Then there should be exactly 1 clash
    And there should be exactly 2 player lists
    And test@email.com should be a player in the black list
    And test@email.com should not be a player in the white list
    When I leave the clash
    Then there should be exactly 0 clashes
    
  Scenario: User joins a roshambo clash, and then leaves
    Given I am signed in as test@email.com
    And a user exists with an email of test2@email.com and password password
    And there is a roshambo game
    And test2@email.com has started a roshambo clash
    Then test@email.com should not be a player in that clash
    And test2@email.com should be a player in that clash
    When I join the clash
    Then test@email.com should be a player in that clash
    And the clash should be startable
    When I leave the clash
    Then test@email.com should not be a player in that clash
    And the clash should not be startable
    