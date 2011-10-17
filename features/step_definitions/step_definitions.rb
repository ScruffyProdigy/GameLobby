require 'stub_game_server'

def create_user(email,password='password')
  User.create(:email=>email,:password=>password,:password_confirmation=>password)
end

def get_user(email)
  User.where(:email=>email).first
end

def get_or_create_user(email)
  get_user(email) or create_user(email)
end

def sign_in email,password
  visit path_to 'sign in'
  fill_in 'email', :with=>email
  fill_in 'password', :with=>password
  click_button 'Sign In!'
end

def sign_up email, password, confirmation
  visit path_to 'sign up'
  fill_in 'user[email]', :with=>email
  fill_in 'user[password]', :with=>password
  fill_in 'user[password_confirmation]', :with=>confirmation
  click_button 'Sign Up!'
end

def stock_clash_options game_name
  {
    'roshambo'=>{:gamename=>'I\'m choosing \'Rock\'',:description=>'You better choose \'Paper\''},
    'chess'=>{:gamename=>'Imma gonna kick your ass',:description=>'And you\'re gonna like it!'}
  }[game_name]
end

def stock_clash_form game_name
  result = {}
  stock_clash_options(game_name).each_pair do |key, value|
    result["form[#{key}]"] = value
  end
  
end

def get_game game_name
  Game.where(:name=>game_name).first
end

def create_game game_name
  Game.create get_game_data game_name
end

def press_join_clash_button list_name
  page.find(:css,"section[list_name='#{list_name}'] .join_clash input[type='submit']").click
end

Given /^Redis is running$/ do
  redis = Redis.new
  begin
    redis.get('foo')
  rescue Errno::ECONNREFUSED
    raise 'You need to run \'redis-server\''
  end
end

Given /^A user does not exist with an email of (.*)$/ do |email|
  user = get_user(email)
  user.should == nil
end

Given /^a user exists with an email of (.*) and password (.*)$/ do |email,password|
  create_user(email,password)
end

Given /^I am signed in as (.*)$/ do |email|
  user = create_user(email,'password')
  sign_in(email,'password')
end

When /^I sign up as (.*) with password (.*) and confirmation (.*),$/ do |email,password,confirmation|
  sign_up email,password,confirmation
end

When /^I sign in as (.*) with password (.*)$/ do |email,password|
  sign_in email,password
end

Then /^I should be signed in$/ do
  page.should have_content('Logged in as ')
end

Then /^I should not be signed in$/ do
  page.should_not have_content('Logged in as ')
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

Given /^there is a (.*) game$/ do |game_name|
  FactoryGirl.create(:game, :name => game_name)
end

When /^I try to create a (.*) clash$/ do |game|
  visit url_for Game.where(:name=>game).first
  click_button "New Clash!"
end

Then /^I should see a clash creation form page$/ do
  page.should have_content("We need some more information")
end

When /^I fill in the (.*) information(.*) and try to create the clash$/ do |game,extra_info|
  stock_clash_options(game).each_pair do |key,value|
    fill_in "form[#{key}]", :with=>value
  end
  click_button 'Create this Clash!'
end

Then /^there should be exactly (\d+) clash(?:es)?$/ do |clash_count|
  Clash.count.should == clash_count.to_i
end

Then /^there should be exactly (\d+) player lists?$/ do |list_count|
  PlayerList.count.should == list_count.to_i
end

Then /^(.*) should be a player in that clash$/ do |email|
  Clash.first.all_user_search.where(:email=>email).should_not be_empty
end


Then /^(.*) should not be a player in that clash$/ do |email|
  Clash.first.all_user_search.where(:email=>email).should be_empty
end

When /^I leave the clash$/ do
  click_button 'Leave Clash!'
end

Then /^(.*) should be a player in the (.*) list$/ do |email,list|
  player_list = Clash.first.find_player_list list
  user = get_user email
  player_list.joined?(user).should == true
end

Then /^(.*) should not be a player in the (.*) list$/ do |email,list|
  player_list = Clash.first.find_player_list list
  user = get_user email
  player_list.joined?(user).should == false
end

When /^I become an? (.*) player for that clash$/ do |list|
  press_join_clash_button list
end

Given /^(.*) has started a (.*) clash$/ do |email,game_name|
  user = get_or_create_user email
  game = get_or_create_game game_name
  clash = Clash.new({:game_id=>game.id})
  form = stock_clash_options game_name
  clash.start_forming user,form
end

When /^I join the clash$/ do
  visit path_to 'first clash'
  press_join_clash_button 'players'
end

Then /^the clash should be startable$/ do
  Clash.first.should be_startable
end

Then /^the clash should not be startable$/ do
  Clash.first.should_not be_startable
end
