class ChildProfile < ApplicationRecord
  # Associations
  belongs_to :primary_caregiver, class_name: 'User', foreign_key: 'primary_caregiver_id'
  has_many :child_memberships, dependent: :destroy
  has_many :users, through: :child_memberships
  has_many :onboarding_sessions, dependent: :destroy
  has_many :child_domain_profiles, dependent: :destroy
  has_many :profile_domains, through: :child_domain_profiles
  has_many :child_goals, dependent: :destroy
  has_many :ai_documents, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :birth_date, presence: true
  validate :birth_date_not_in_future

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Soft delete
  def soft_delete!
    update(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  private

  def birth_date_not_in_future
    return unless birth_date.present?

    errors.add(:birth_date, 'cannot be in the future') if birth_date > Date.today
  end
end
