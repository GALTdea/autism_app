class ChildProfileResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :birth_date
  attribute :diagnosis_summary
  attribute :deleted_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :preferred_contexts

  # Associations
  attribute :primary_caregiver
  attribute :child_memberships
  attribute :users
  attribute :onboarding_sessions
  attribute :child_domain_profiles
  attribute :profile_domains
  attribute :child_goals
  attribute :ai_documents
  attribute :daily_recommendations
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
