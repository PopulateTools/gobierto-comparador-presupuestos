# ABOUTME: Migration to drop the unused activities table
# ABOUTME: Part of PostgreSQL to SQLite database migration

class DropActivitiesTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :activities
  end

  def down
    create_table :activities do |t|
      t.references :trackable, polymorphic: true
      t.references :owner, polymorphic: true
      t.references :recipient, polymorphic: true
      t.string :key
      t.text :parameters
      t.string :ip
      t.timestamps
    end
  end
end
