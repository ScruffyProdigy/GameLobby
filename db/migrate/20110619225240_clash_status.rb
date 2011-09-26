class ClashStatus < ActiveRecord::Migration
  def self.up
    change_table :clashes do |t|
      t.string :status, :default=>'forming'
    end
  end

  def self.down
    remove_column :clashes, :status
  end
end
