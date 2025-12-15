class AddAssessmentToOnboardingSessions < ActiveRecord::Migration[8.0]
  def change
    # add_reference automatically creates an index, so we don't need add_index separately
    add_reference :onboarding_sessions, :assessment, null: true, foreign_key: true, index: true
  end
end
