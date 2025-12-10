class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :onboarding_session, onboarding_sessions: true, null: false, foreign_key: true
      t.references :question, questions: true, null: false, foreign_key: true
      t.references :question_option, question_options: true, null: false, foreign_key: true
      t.integer :numeric_value
      t.text :free_text

      t.timestamps
    end
  end
end
