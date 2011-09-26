class CreateGameDevelopers < ActiveRecord::Migration
  def self.up
    create_table :game_developers do |t|
      t.belongs_to :user
      t.belongs_to :game
      t.timestamps
    end
  end

  def self.down
    drop_table :game_developers
  end
end
