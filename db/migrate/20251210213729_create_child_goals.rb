class CreateChildGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :child_goals do |t|
      t.references :child_profile, child_profiles: true, null: false, foreign_key: true
      t.references :profile_domain, profile_domains: true, null: false, foreign_key: true
      t.string :status
      t.string :short_title
      t.text :description
      t.integer :priority_rank
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
