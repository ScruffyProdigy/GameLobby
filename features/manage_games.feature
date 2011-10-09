Feature: Manage Games
  In order to share my games with the public
  As a Game Developer
  I want to manage my games
  
  Background:
    Given I am signed in as test@email.com
    And Redis is running
  
  Scenario: I create a game and then later delete a game
    Given no games exist
    When I create a game with name TestGame, site http://testgame.com, and comm http://testgame.com/comm
    Then there should only be 1 game
    When I go to the first game page
    Then I should be a developer for that game
    When I delete that game
    Then there should be no games
        
  Scenario: Somebody else created a game
    Given a game exists with name TestGame, site http://testgame.com, and comm http://testgame.com/comm
    When I go to the first game page
    Then I should not be a developer for that game