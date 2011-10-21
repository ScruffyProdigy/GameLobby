require 'net/http'
require 'uri'
require 'json'

require "redispusher.rb"

class Game < ActiveRecord::Base
  validates :name, :presence=>true
  validates :site, :presence=>true
  validates :comm, :presence=>true
  
  has_many :clashes
  after_create :push_creation
  before_destroy :push_destruction
  
  def format_message message
    #   the post_form method below only takes a specific format for hashes.  First reformat the current message to make sure it fits 
    formatted_message = {}
    message.each_pair do |key,value|
      formatted_message[key.to_s] = value
    end
    
    return formatted_message
  end
  
  def communicate_with_game_server message
    #  separate out the host, port, and destination from the stored URI
    uri = URI.parse comm
    
    #  send out the POST    
    res = Net::HTTP.post_form(uri,message)
    if res.class == Net::HTTPSuccess or res.class == Net::HTTPRedirection
      result = JSON.parse res.body
      logger.info("Response: #{result}")
      return result
    end
    logger.error("Error Response:#{res.class}")
    return nil
  end
  
  def send_message message
    formatted_message = format_message message
    logger.info("Message to \"#{name}\": #{formatted_message}")
    
    return communicate_with_game_server formatted_message
  end
  
  def is_developer? user
    GameDeveloper.where(:game_id=>self.id,:user_id=>user.id).any?
  end
  
  def push_creation
    RedisPusher.push_data('games',{:type=>"new_game",:id=>self.id,:name=>self.name})
  end
  
  def push_destruction
    RedisPusher.push_data('games',{:type=>"game_gone",:id=>self.id,:name=>self.name})
  end
end
