class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.string :code, null: false
      t.text :text, null: false
      t.string :domain
      t.string :response_type, null: false
      t.integer :position
      t.references :profile_domain, null: false, foreign_key: true

      t.timestamps
    end

    add_index :questions, :code, unique: true
    add_index :questions, [:profile_domain_id, :position]
    add_index :questions, :domain
  end
end
