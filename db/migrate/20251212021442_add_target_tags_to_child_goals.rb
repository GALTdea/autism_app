class AddTargetTagsToChildGoals < ActiveRecord::Migration[8.0]
  def change
    add_column :child_goals, :target_tags, :jsonb, default: []
    # Stores specificity tags for goal matching (e.g., denied_access, transitions_off_screen)
    add_index :child_goals, :target_tags, using: :gin
  end
end
