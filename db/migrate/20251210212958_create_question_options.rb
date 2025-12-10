class CreateQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :question_options do |t|
      t.references :question, null: false, foreign_key: true
      t.string :label, null: false
      t.integer :value, null: false
      t.integer :position

      t.timestamps
    end

    add_index :question_options, [:question_id, :position]
  end
end
