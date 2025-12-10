class CreateChildGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :child_goals do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :profile_domain, null: false, foreign_key: true
      t.string :status, null: false, default: 'suggested'
      t.string :short_title, null: false
      t.text :description
      t.integer :priority_rank
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :child_goals, :status
    add_index :child_goals, [:child_profile_id, :status]
    add_index :child_goals, :deleted_at
    add_index :child_goals, :priority_rank
  end
end
