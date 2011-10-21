Feature: Manage Sessions
  In order to participate in this site
  As a user
  I want to become a user and manage my sessions
  
  Scenario: User wants to sign up
    When I sign up as test@email.com with password password and confirmation password,
    Then a user with an email of test@email.com should exist
    And I should be signed in
  
  Scenario: User is not signed up
    When I sign in as test@email.com with password password
    Then I should not be signed in
    
  Scenario: Existing user wants to sign up (with an email thats already taken)  
    Given a user exists with an email of test@email.com and password password
    When I sign up as test@email.com with password password and confirmation password,
    Then I should not be signed in
    And there should only be 1 user with email test@email.com
    
  Scenario: Existing user wants to sign in
    Given a user exists with an email of test@email.com and password password
    When I sign in as test@email.com with password password
    Then I should be signed in
    
  Scenario: User wants to sign out
    Given I am signed in as test@email.com
    When I go to the sign out page
    Then I should not be signed in
    
  Scenario: User messes up password confirmation
    When I sign up as test@email.com with password password and confirmation mistake,
    Then no user with an email of test@email.com should exist
    And I should not be signed in
    
  Scenario: User forgets email during sign up
    When I sign up as  with password password and confirmation password,
    Then no users should exist
    And I should not be signed in
    
  Scenario: User forgets password during sign up
    When I sign up as test@email.com with password  and confirmation ,
    Then no users should exist
    And I should not be signed in
    
  Scenario: User forgets password confirmation during sign up
    When I sign up as test@email.com with password password and confirmation ,
    Then no users should exist
    And I should not be signed in