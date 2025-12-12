class AddPreferredContextsToChildProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :child_profiles, :preferred_contexts, :json, default: []
    # Stores: preferred times, duration preferences, environment constraints, materials tolerance
    add_index :child_profiles, :preferred_contexts
  end
end
