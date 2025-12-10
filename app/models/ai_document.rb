class AiDocument < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :onboarding_session, optional: true
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'

  # Enums
  enum :document_type, {
    profile_summary: 'profile_summary',
    onboarding_summary: 'onboarding_summary',
    weekly_summary: 'weekly_summary'
  }

  # Validations
  validates :document_type, presence: true
  validates :content_markdown, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_type, ->(type) { where(document_type: type) }
  scope :latest_for_type, ->(type) { for_type(type).recent.limit(1) }
end
