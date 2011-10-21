# Read about factories at http://github.com/thoughtbot/factory_girl
require "stub_game_server"

Factory.define :game do |g|
  g.name 'First game'
  g.sequence(:comm) { |i| "http://api.firstgame.com:#{8000+i}" }
  g.site { |game| StubGameServer.create_server game.name,game.comm
    "http://www.firstgame.com" 
  }
end
