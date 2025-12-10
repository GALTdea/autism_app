class CreateChildProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :child_profiles do |t|
      t.references :primary_caregiver, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.date :birth_date, null: false
      t.text :diagnosis_summary
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :child_profiles, :deleted_at
  end
end
