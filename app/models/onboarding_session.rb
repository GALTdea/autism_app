class OnboardingSession < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :user
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
    return 0 if child_profile.profile_domains.empty?

    answered_domains = answers.joins(question: :profile_domain)
                             .select('DISTINCT profile_domains.id')
                             .count
    total_domains = child_profile.profile_domains.count

    return 0 if total_domains.zero?

    (answered_domains.to_f / total_domains * 100).round
  end
end
