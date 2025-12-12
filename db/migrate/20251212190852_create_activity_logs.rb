class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :activity_template, null: false, foreign_key: true
      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.boolean :completed, null: false, default: false
      t.integer :enjoyment, null: false # enum: 0=thumbs_down, 1=neutral, 2=thumbs_up
      t.text :note

      t.timestamps
    end

    add_index :activity_logs, [ :child_profile_id, :occurred_at ]
    add_index :activity_logs, [ :activity_template_id, :occurred_at ]
    add_index :activity_logs, [ :child_profile_id, :activity_template_id, :occurred_at ]
    add_index :activity_logs, :enjoyment
    add_index :activity_logs, :completed
  end
end
