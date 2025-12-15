class CreateAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :assessments do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.boolean :is_default, default: false, null: false
      t.timestamps
    end

    add_index :assessments, [ :name, :version ], unique: true
    add_index :assessments, :is_default
    add_index :assessments, :active
  end
end
