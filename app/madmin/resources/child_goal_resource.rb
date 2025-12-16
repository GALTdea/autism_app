class ChildGoalResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :status
  attribute :short_title
  attribute :description
  attribute :priority_rank
  attribute :deleted_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :target_tags

  # Associations
  attribute :child_profile
  attribute :profile_domain

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
