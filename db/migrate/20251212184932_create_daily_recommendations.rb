class CreateDailyRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_recommendations do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.date :date, null: false
      t.json :activity_template_ids, null: false, default: [] # Array of IDs
      t.datetime :computed_at, null: false

      t.timestamps
    end

    add_index :daily_recommendations, [ :child_profile_id, :date ], unique: true
    add_index :daily_recommendations, :date
  end
end
