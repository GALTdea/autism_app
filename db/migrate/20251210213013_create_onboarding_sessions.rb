class CreateOnboardingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding_sessions do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'in_progress'

      t.timestamps
    end

    add_index :onboarding_sessions, :status
    add_index :onboarding_sessions, [:child_profile_id, :status]
  end
end
