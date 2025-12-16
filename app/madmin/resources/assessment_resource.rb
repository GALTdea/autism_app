class AssessmentResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :version
  attribute :description
  attribute :active
  attribute :is_default
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :assessment_domains, form: false
  attribute :profile_domains, form: false
  attribute :onboarding_sessions, form: false

  # Note: Use model scopes (Assessment.active, Assessment.default) in controllers

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    "#{record.name} v#{record.version}"
  end

  # Customize the default sort column and direction.
  def self.default_sort_column
    "name"
  end

  def self.default_sort_direction
    "asc"
  end
end
