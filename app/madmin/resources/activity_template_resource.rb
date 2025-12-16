class ActivityTemplateResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :duration_minutes
  attribute :materials
  attribute :parent_script
  attribute :variation
  attribute :secondary_target_ids
  attribute :target_tags
  attribute :age_bands
  attribute :language_level_required
  attribute :motor_demands
  attribute :difficulty_level
  attribute :energy_level
  attribute :contexts
  attribute :materials_category
  attribute :scripts_by_level
  attribute :sensory_fit
  attribute :noise_level
  attribute :movement_level
  attribute :variations
  attribute :prerequisites
  attribute :sensory_profile_tags
  attribute :supports_concerns
  attribute :active
  attribute :position
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :primary_target
  attribute :activity_logs

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
