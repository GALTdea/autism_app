class CreateChildDomainProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :child_domain_profiles do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :profile_domain, null: false, foreign_key: true
      t.integer :level_estimate
      t.text :strengths_summary
      t.text :needs_summary

      t.timestamps
    end

    add_index :child_domain_profiles, [ :child_profile_id, :profile_domain_id ], unique: true
  end
end
