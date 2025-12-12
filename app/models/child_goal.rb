class ChildGoal < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :profile_domain

  # Enums
  enum :status, {
    suggested: "suggested",
    active: "active",
    paused: "paused",
    archived: "archived"
  }

  # Validations
  validates :status, presence: true
  validates :short_title, presence: true
  validates :priority_rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :target_tags_is_array, if: -> { target_tags.present? }

  private

  def target_tags_is_array
    errors.add(:target_tags, "must be an array") unless target_tags.is_a?(Array)
  end

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :suggested, -> { where(status: "suggested") }
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :ordered_by_priority, -> { order(priority_rank: :asc, created_at: :asc) }
  scope :for_domain, ->(domain_id) { where(profile_domain_id: domain_id) }

  # Soft delete
  def soft_delete!
    update(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
