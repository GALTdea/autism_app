class AddAssessmentToOnboardingSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :onboarding_sessions, :assessment, null: true, foreign_key: true
    add_index :onboarding_sessions, :assessment_id
  end
end
