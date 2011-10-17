# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :game do
    name 'First game'
    site 'http://www.firstgame.com'
    comm 'http://api.firstgame.com'
  end
end
