require "redispusher.rb"

class Player < ActiveRecord::Base
  belongs_to :player_list
  belongs_to :user
  
  after_create :push_creation
  before_destroy :push_destruction
  
  after_create :notify_clash_of_new_player
  after_destroy :notify_clash_of_lost_player
  
  validates :user_id, :presence=>{:message=>"User Info Required To Add Player (Hint: You're probably not logged in)"}
  
  def take_data data
    public_data = data['publicdata'] if data['publicdata']  #public data is data that other players can see.  API will need to cover how to format it
    private_data = data['privatedata'] if data['privatedata'] #private data is data that other players can't see.  We won't need to do anything special with it; it's just an arbitrary chunk of bits.  API doesn't need to cover this
  end
  
  def clash
    self.player_list.clash
  end
  
  def leave_clash
    raise PlayerLeaveError, "Can't leave clash if clash isn't still forming" unless self.clash.forming?
    self.destroy
  end
  
protected
  
  def notify_clash_of_new_player
    self.clash.new_player_notification
  end
  
  def notify_clash_of_lost_player
    self.clash.lost_player_notification
  end
  
  def push_creation
    message = {:type=>"new_player"}
    message[:id] = self.id
    message[:user_id] = self.user.id
    message[:name] = self.user.email
#   messsage[:public_data] = self.public_data
    message[:startable] = true if(self.clash.startable?)
    message[:list_full] = true if(self.player_list.full?)
    RedisPusher.push_data("clash#{self.clash.id}",{:type=>"new_player",:id=>self.id,:user_id=>self.user.id,:name=>self.user.email,:list=>self.player_list.name,:full=>self.player_list.full?,:startable=>self.clash.startable?});
  end
  
  def push_destruction
    RedisPusher.push_data("clash#{self.clash.id}",{:type=>"player_gone",:id=>self.id,:user_id=>self.user.id,:name=>self.user.email});    
  end
end
