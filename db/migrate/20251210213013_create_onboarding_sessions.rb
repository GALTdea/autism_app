class CreateOnboardingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding_sessions do |t|
      t.references :child_profile, child_profiles: true, null: false, foreign_key: true
      t.references :user, users: true, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
