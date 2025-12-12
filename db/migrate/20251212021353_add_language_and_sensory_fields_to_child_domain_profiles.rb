class AddLanguageAndSensoryFieldsToChildDomainProfiles < ActiveRecord::Migration[8.0]
  def change
    # For communication domain
    add_column :child_domain_profiles, :expressive_level, :string # enum: pre_verbal, single_words, short_phrases, sentences
    add_column :child_domain_profiles, :receptive_level, :string # enum: pre_verbal, single_words, short_phrases, sentences
    add_column :child_domain_profiles, :supports, :jsonb, default: [] # Array of support types
    
    # For sensory domain
    add_column :child_domain_profiles, :seeking_level, :integer # 0-5 scale
    add_column :child_domain_profiles, :avoiding_level, :integer # 0-5 scale
    add_column :child_domain_profiles, :sensitivity_tags, :jsonb, default: [] # Array of sensitivity tags
    
    add_index :child_domain_profiles, :expressive_level
    add_index :child_domain_profiles, :receptive_level
    add_index :child_domain_profiles, :sensitivity_tags, using: :gin
  end
end
