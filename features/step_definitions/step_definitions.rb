require 'stub_game_server'

def get_user email
  User.where(:email=>email).first
end

def get_game(name)
  Game.where(:name=>name).first
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

def press_join_clash_button list_name
  page.find(:css,"section[list_name='#{list_name}'] .join_clash input[type='submit']").click
end

def get_conditions string
  words = string.lstrip.split
  conditions = {}
  if words.shift == 'with'
    until words.empty?
      condition = words.shift
      next if condition == 'and'
      if condition == 'a' or condition == 'an'
        condition = words.shift
        words.shift.should == 'of'
      end
      value = words.shift
      if value
        value.chop if value[-1] == ','
        conditions[condition.to_sym] = value
      end
    end
  end
  return conditions
end

def select_with_conditions selection,conditions
  conditions.each_pair do |key,value|
    selection = selection.where(key=>value)
  end
  selection
end

def model_count model,conditions
  conditions ||= ""
  conditions = get_conditions conditions
  selection = model.camelize.singularize.constantize
  selection = select_with_conditions selection,conditions
  selection.count.should
end

Given /^a (.*) exists (.*)$/ do |model,conditions|
  conditions = get_conditions conditions
  FactoryGirl.create(model.to_sym,conditions)
end

Given /^I am signed in as (.*)$/ do |email|
  user = FactoryGirl.create :user,:email=>email
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

Then /^a ([^\s]*)(.*)? should exist$/ do |model,conditions|
  model_count(model,conditions).should > 0
end

Then /^no ([^\s]*)(.*)? should exist$/ do |model,conditions|
  model_count(model,conditions).should == 0
end

Then /^there should only be (\d) ([^\s]*)(.*)?$/ do |number,model,conditions|
  model_count(model,conditions).should == number.to_i
end

Then /^there should be no ([^\s]*)(.*)?$/ do |model,conditions|
  model_count(model,conditions).should == 0
end

Then /^there should be exactly (\d+) ([^\s]*)(.*)?$/ do |number,model,conditions|
  model_count(model,conditions).should == number.to_i
end


When /^I create a game(.*)$/ do |conditions|
  conditions = get_conditions conditions
  visit path_to 'new game'
  conditions.each_pair do |condition,status|
    fill_in "game[#{condition}]",:with=>status
  end
  click_button 'Make Game!'
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

Given /^there is a (.*) game(.*)?$/ do |game_name,conditions|
  conditions = get_conditions conditions
  conditions[:name] = game_name
  FactoryGirl.create(:game,conditions)
end

When /^I try to create a (.*) clash$/ do |game|
  visit url_for Game.where(:name=>game).first
  click_button "New Clash!"
end

Then /^I should see a clash creation form page$/ do
  page.should have_content("We need some more information")
end

When /^I fill in the (.*) information(.*) and try to create the clash$/ do |game,conditions|
  conditions.reverse.chop.reverse if conditions[0] == ','
  conditions.chop if conditions[-1] == ','
  stock_clash_options(game).each_pair do |key,value|
    fill_in "form[#{key}]", :with=>value
  end
#  conditions.each_pair do |key,value|
  #  fill_in "form[#{key}]", :with=>value
#  end
  click_button 'Create this Clash!'
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
  user = get_user(email) or FactoryGirl.create(:user,:email=>email)
  game = get_game(game_name) or FactoryGirl.create(:game,:name=>game_name)
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

When /^I start the clash$/ do
  begin
    class ActionController::Base
      alias_method :old_redirect_to, :redirect_to
    
      def redirect_to url
        render :inline=>StubGameServer.get_from_server(url)
      end
    end
    
    click_button 'Start Clash!'
  ensure 
    class ActionController::Base
      alias_method :redirect_to, :old_redirect_to
    end
  end
end

Then /^I should be sent to the game page$/ do
  pending
end
