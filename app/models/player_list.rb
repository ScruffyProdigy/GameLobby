class PlayerList < ActiveRecord::Base
  belongs_to :clash
  has_many :players
  
  
  def joined? user
    Player.where(:player_list_id=>self.id,:user_id=>user.id).any?
  end
  
  def full?
    Player.where(:player_list_id=>self.id).count >= self.player_count
  end
end
