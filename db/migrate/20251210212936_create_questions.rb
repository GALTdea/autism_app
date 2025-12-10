class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.string :code
      t.text :text
      t.string :domain
      t.string :response_type
      t.integer :position
      t.references :profile_domain, profile_domains: true, null: false, foreign_key: true

      t.timestamps
    end
  end
end
