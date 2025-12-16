class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email
  attribute :password, form: true, type: :password
  attribute :password_confirmation, form: true, type: :password
  attribute :role
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :child_memberships, form: false
  attribute :child_profiles, form: false
  attribute :primary_child_profiles, form: false
  attribute :onboarding_sessions, form: false
  attribute :ai_documents, form: false

  # Note: Scopes can be added in the controller or use model scopes

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    record.email
  end

  # Customize the default sort column and direction.
  def self.default_sort_column
    "created_at"
  end

  def self.default_sort_direction
    "desc"
  end
end
