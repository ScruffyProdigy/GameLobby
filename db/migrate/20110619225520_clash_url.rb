class ClashUrl < ActiveRecord::Migration
  def self.up
    change_table :clashes do |t|
      t.string :url
    end
  end

  def self.down
    remove_column :clashes,:url
  end
end
