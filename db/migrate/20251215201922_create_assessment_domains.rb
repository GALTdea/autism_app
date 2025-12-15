class CreateAssessmentDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_domains do |t|
      t.references :assessment, null: false, foreign_key: { on_delete: :cascade }
      t.references :profile_domain, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps
    end

    add_index :assessment_domains, [:assessment_id, :profile_domain_id], unique: true, name: "index_assessment_domains_on_assessment_and_profile_domain"
    add_index :assessment_domains, [:assessment_id, :position]
  end
end
