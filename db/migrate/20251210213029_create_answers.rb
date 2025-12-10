class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :question_option, null: true, foreign_key: true
      t.integer :numeric_value
      t.text :free_text

      t.timestamps
    end

    add_index :answers, [:onboarding_session_id, :question_id], unique: true
    add_index :answers, :numeric_value
  end
end
