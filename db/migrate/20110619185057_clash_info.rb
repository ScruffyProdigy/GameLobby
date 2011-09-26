class ClashInfo < ActiveRecord::Migration
  def self.up
    change_table :clashes do |t|
      t.string :name
      t.string :description
      t.integer :player_count
      t.string :public_data
      t.string :private_data
    end
    
    change_table :players do |t|
      t.string :publc_data
      t.string :private_data
    end
  end

  def self.down
    remove_column :clashes, :name
    remove_column :clashes, :description
    remove_column :clashes, :player_count
    remove_column :clashes, :public_data
    remove_column :clashes, :private_data
    
    remove_column :players, :public_data
    remove_column :players, :private_data
  end
end
