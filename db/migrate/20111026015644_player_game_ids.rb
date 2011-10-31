class PlayerGameIds < ActiveRecord::Migration
  def up
    add_column :players, :in_game_id, :string, :default=>''
  end

  def down
    remove_column :players, :in_game_id
  end
end
