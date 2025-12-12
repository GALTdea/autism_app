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

  # Helper methods for Phase 2
  def age
    return nil unless birth_date
    today = Date.today
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def age_band
    return nil unless age
    ActivityTemplate.age_band_for_age(age)
  end

  def language_profile
    communication_profile = child_domain_profiles
      .joins(:profile_domain)
      .find_by(profile_domains: { key: 'communication' })
    return nil unless communication_profile

    {
      expressive_level: communication_profile.expressive_level,
      receptive_level: communication_profile.receptive_level,
      supports: communication_profile.supports || []
    }
  end

  def sensory_profile
    sensory_domain_profile = child_domain_profiles
      .joins(:profile_domain)
      .find_by(profile_domains: { key: 'sensory' })
    return nil unless sensory_domain_profile

    {
      seeking_level: sensory_domain_profile.seeking_level,
      avoiding_level: sensory_domain_profile.avoiding_level,
      sensitivity_tags: sensory_domain_profile.sensitivity_tags || []
    }
  end

  def top_goals(limit = 3)
    child_goals
      .where(status: ['active', 'suggested'])
      .where(deleted_at: nil)
      .order(priority_rank: :asc, created_at: :asc)
      .limit(limit)
  end

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
