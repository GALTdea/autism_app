class CreateAiDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_documents do |t|
      t.string :document_type, null: false
      t.references :child_profile, null: false, foreign_key: true
      t.references :onboarding_session, null: true, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :content_markdown, null: false

      t.timestamps
    end

    add_index :ai_documents, :document_type
    add_index :ai_documents, [:child_profile_id, :document_type, :created_at]
  end
end
