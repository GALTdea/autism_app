class CreateChildDomainProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :child_domain_profiles do |t|
      t.references :child_profile, child_profiles: true, null: false, foreign_key: true
      t.references :profile_domain, profile_domains: true, null: false, foreign_key: true
      t.integer :level_estimate
      t.text :strengths_summary
      t.text :needs_summary

      t.timestamps
    end
  end
end
