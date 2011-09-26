class CreatePlayerLists < ActiveRecord::Migration
  def self.up
    create_table :player_lists do |t|
      t.string :name
      t.integer :player_count
      t.belongs_to :clash

      t.timestamps
    end
    
    remove_column :players, :clash_id
    add_column :players, :player_list_id, :integer
    remove_column :clashes, :player_count
  end

  def self.down
    drop_table :player_lists
    remove_column :players, :player_list_id
    add_column :players, :clash_id, :integer
    add_column :clashes, :player_count, :integer
  end
end
