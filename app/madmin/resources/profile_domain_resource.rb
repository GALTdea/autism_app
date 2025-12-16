class ProfileDomainResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :key
  attribute :label
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :questions, form: false
  attribute :child_domain_profiles, form: false
  attribute :child_profiles, form: false
  attribute :child_goals, form: false
  attribute :assessment_domains, form: false
  attribute :assessments, form: false

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    record.label
  end

  # Customize the default sort column and direction.
  def self.default_sort_column
    "label"
  end

  def self.default_sort_direction
    "asc"
  end
end
