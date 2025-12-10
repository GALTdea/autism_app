class CreateChildProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :child_profiles do |t|
      t.references :primary_caregiver, users: true, null: false, foreign_key: true
      t.string :name
      t.date :birth_date
      t.text :diagnosis_summary
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
