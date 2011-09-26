class CreateClashes < ActiveRecord::Migration
  def self.up
    create_table :clashes do |t|
      t.belongs_to :game
      t.timestamps
    end
  end

  def self.down
    drop_table :clashes
  end
end
