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
  return case page
  when 'sign in'
    log_in_path
  when 'sign out'
    log_out_path
  when 'sign up'
    sign_up_path
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