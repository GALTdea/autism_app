class CreateActivityTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_templates do |t|
      # Foreign key to ProfileDomain
      t.references :primary_target, null: false, foreign_key: { to_table: :profile_domains }
      
      # Visible fields
      t.string :title, null: false
      t.integer :duration_minutes, null: false # 5 or 10
      t.text :materials, null: false
      t.text :parent_script, null: false # Base script
      t.text :variation, null: false
      
      # Key filter fields (columns for efficient querying)
      t.jsonb :secondary_target_ids, default: [] # Array of profile_domain_ids
      t.jsonb :target_tags, default: [] # Specificity layer
      t.jsonb :age_bands, null: false, default: [] # Array: ["3-5", "6-8", "9-11"]
      t.string :language_level_required # enum: pre_verbal, single_words, short_phrases, sentences
      t.string :motor_demands # enum: low, medium, high
      t.integer :difficulty_level, null: false # 1-5
      t.string :energy_level # enum: calming, neutral, energizing
      t.jsonb :contexts, default: [] # Array: ["home", "car", "park", etc.]
      t.string :materials_category # enum: household, toys, craft, none
      
      # Long-tail metadata (JSONB)
      t.jsonb :scripts_by_level, default: {} # { "single_words": "...", "phrases": "...", "sentences": "..." }
      t.jsonb :sensory_fit, default: {} # Sensory compatibility details
      t.jsonb :noise_level, default: {} # Noise requirements/characteristics
      t.jsonb :movement_level, default: {} # Movement requirements/characteristics
      t.jsonb :variations, default: [] # Additional variations beyond primary
      t.jsonb :prerequisites, default: {} # Activity prerequisites
      t.jsonb :sensory_profile_tags, default: [] # Sensory characteristics
      t.jsonb :supports_concerns, default: [] # Concern tags
      
      t.boolean :active, default: true, null: false
      t.integer :position # For ordering
      
      t.timestamps
    end
    
    # Indexes for key filter fields (columns)
    add_index :activity_templates, :primary_target_id
    add_index :activity_templates, :active
    add_index :activity_templates, :duration_minutes
    add_index :activity_templates, :difficulty_level
    add_index :activity_templates, :energy_level
    add_index :activity_templates, :language_level_required
    add_index :activity_templates, :motor_demands
    add_index :activity_templates, :materials_category
    
    # GIN indexes for JSONB arrays (efficient querying)
    add_index :activity_templates, :secondary_target_ids, using: :gin
    add_index :activity_templates, :target_tags, using: :gin
    add_index :activity_templates, :age_bands, using: :gin
    add_index :activity_templates, :contexts, using: :gin
    add_index :activity_templates, :sensory_profile_tags, using: :gin
    add_index :activity_templates, :supports_concerns, using: :gin
  end
end
