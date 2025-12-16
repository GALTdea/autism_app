class AddScoringConfigToAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :assessments, :scoring_config, :jsonb, default: {}
    add_index :assessments, :scoring_config, using: :gin
  end
end
