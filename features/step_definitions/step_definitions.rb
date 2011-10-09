Given /^Redis is running$/ do
  redis = Redis.new
  begin
    redis.get('foo')
  rescue Errno::ECONNREFUSED
    raise 'You need to run \'redis-server\''
  end
end

Given /^A user does not exist with an email of (.*)$/ do |email|
  user = User.where(:email=>email).first
  user.should == nil
end

Given /^a user exists with an email of (.*) and password (.*)$/ do |email,password|
  User.create(:email=>email,:password=>password,:password_confirmation=>password)
end

Given /^I am signed in as (.*)$/ do |email|
  user = User.create(:email=>email,:password=>'password')
  sign_in email,'password'
end

#When /^I sign up as (.*) with password (.*)$/ do |email,password|
#  sign_up email,password,password
#end

When /^I sign up as (.*) with password (.*) and confirmation (.*),$/ do |email,password,confirmation|
  sign_up email,password,confirmation
end

When /^I sign in as (.*) with password (.*)$/ do |email,password|
  sign_in email,password
end

When /^I go to the (.*) page$/ do |page|
  visit path_to page
end

Then /^I should be signed in$/ do
  page.should have_content('Logged in as ')
end

Then /^I should not be signed in$/ do
  page.should_not have_content('Logged in as ')
end

def path_to page
  case page
  when 'sign in'
    log_in_path
  when 'sign out'
    log_out_path
  when 'sign up'
    sign_up_path
  when 'new game'
    new_game_path
  when 'first game'
    game_path 1
  else
    raise "Undefined Page in path_to"
  end
end

Then /^a user with an email of (.*) should exist$/ do |email|
  user = User.where(:email=>email).first
  user.should_not == nil
end

Then /^no user with an email of (.*) should exist$/ do |email|
  user = User.where(:email=>email).first
  user.should == nil
end

Then /^there should only be one user with email (.*)$/ do |email|
  User.where(:email=>email).count.should == 1
end

Then /^no users should exist$/ do
  User.count.should == 0
end

def sign_in email,password
  visit path_to 'sign in'
  fill_in 'email', :with=>email
  fill_in 'password', :with=>password
  click_button 'Sign In!'
end

def sign_up email,password,confirmation
  visit path_to 'sign up'
  fill_in 'user[email]', :with=>email
  fill_in 'user[password]', :with=>password
  fill_in 'user[password_confirmation]', :with=>confirmation
  click_button 'Sign Up!'
end

Given /^no games exist$/ do
  Game.count.should == 0
end

When /^I create a game with name (.*), site (.*), and comm (.*)$/ do |name,site,comm|
  visit path_to 'new game'
  fill_in 'game[name]', :with=>name
  fill_in 'game[site]', :with=>site
  fill_in 'game[comm]', :with=>comm
  click_button 'Make Game!'
end

Then /^there should only be (\d+) games?$/ do |number|
  Game.count.should == number.to_i
end

Then /^I should be a developer for that game$/ do
  page.should have_content('Developer Info')
end

Then /^I should not be a developer for that game$/ do
  page.should_not have_content('Developer Info')
end

When /^I delete that game$/ do
  click_link 'Edit this game\'s info'
  click_button 'Delete this game'
end

Then /^there should be no games$/ do
  Game.count.should == 0
end

Given /^a game exists with name (.*), site (.*), and comm (.*)$/ do |name,site,comm|
  Game.create(:name=>name,:site=>site,:comm=>comm)
end