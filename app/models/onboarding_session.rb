class OnboardingSession < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :user
  belongs_to :assessment, optional: true
  has_many :answers, dependent: :destroy
  has_many :questions, through: :answers
  has_many :ai_documents, dependent: :destroy

  # Enums
  enum :status, {
    in_progress: 'in_progress',
    completed: 'completed'
  }

  # Validations
  validates :status, presence: true

  # Scopes
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def complete!
    update(status: 'completed')
  end

  def completed?
    status == 'completed'
  end

  def progress_percentage
    # Use assessment domains if assessment is present, otherwise fall back to all domains
    domains_to_check = assessment&.profile_domains || child_profile.profile_domains
    return 0 if domains_to_check.empty?

    profile_domain_ids = domains_to_check.pluck(:id)
    answered_domains = answers.joins(question: :assessment_domain)
                             .where(assessment_domains: { profile_domain_id: profile_domain_ids })
                             .where.not(assessment_domains: { profile_domain_id: nil })
                             .select('DISTINCT assessment_domains.profile_domain_id')
                             .count
    total_domains = domains_to_check.count

    return 0 if total_domains.zero?

    (answered_domains.to_f / total_domains * 100).round
  end
end
