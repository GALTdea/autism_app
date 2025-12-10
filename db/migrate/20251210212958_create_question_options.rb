class CreateQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :question_options do |t|
      t.references :question, questions: true, null: false, foreign_key: true
      t.string :label
      t.integer :value
      t.integer :position

      t.timestamps
    end
  end
end
