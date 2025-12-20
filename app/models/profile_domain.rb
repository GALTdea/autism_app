class ProfileDomain < ApplicationRecord
  # Associations
  has_many :questions, dependent: :destroy
  has_many :child_domain_profiles, dependent: :destroy
  has_many :child_profiles, through: :child_domain_profiles
  has_many :child_goals, dependent: :destroy
  has_many :assessment_domains, dependent: :destroy
  has_many :assessments, through: :assessment_domains

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :label, presence: true

  # Scopes
  scope :ordered, -> { order(:label) }

  # Validation Helpers

  # Check if domain has any questions
  def has_questions?
    questions.any?
  end

  # Check if domain can be safely deleted
  # Returns false if domain is being used in:
  # - Assessments
  # - Child profiles (through child_domain_profiles)
  # - Onboarding sessions (through assessments)
  def can_be_deleted?
    return false if assessments.any?
    return false if child_profiles.any?

    # Check for onboarding sessions that use assessments containing this domain
    assessment_ids = assessments.pluck(:id)
    if assessment_ids.any?
      return false if OnboardingSession.where(assessment_id: assessment_ids).exists?
    end

    true
  end

  # Get reasons why domain cannot be deleted
  def deletion_blockers
    blockers = []

    blockers << "Domain is used in #{assessments.count} assessment(s)" if assessments.any?
    blockers << "Domain is associated with #{child_profiles.count} child profile(s)" if child_profiles.any?

    assessment_ids = assessments.pluck(:id)
    if assessment_ids.any?
      onboarding_count = OnboardingSession.where(assessment_id: assessment_ids).count
      blockers << "Domain is used in #{onboarding_count} onboarding session(s)" if onboarding_count > 0
    end

    blockers
  end

  # Check if all questions have required options
  # Scale and multi_choice questions must have at least one option
  # Text questions don't require options
  def is_complete?
    return false unless has_questions?

    questions.each do |question|
      # Scale and multi_choice questions require options
      if question.scale? || question.multi_choice?
        return false if question.question_options.empty?
      end
      # Text questions don't require options, so they're always "complete"
    end

    true
  end

  # Get list of incomplete questions (questions missing required options)
  def incomplete_questions
    questions.select do |question|
      (question.scale? || question.multi_choice?) && question.question_options.empty?
    end
  end

  # Get validation status with details
  def validation_status
    {
      has_questions: has_questions?,
      is_complete: is_complete?,
      can_be_deleted: can_be_deleted?,
      incomplete_questions_count: incomplete_questions.count,
      deletion_blockers: deletion_blockers
    }
  end

  # Integration & Impact Analysis Methods

  # Get assessments that use this domain with their session counts
  def assessments_with_impact
    assessments.includes(:onboarding_sessions).map do |assessment|
      {
        assessment: assessment,
        session_count: assessment.onboarding_sessions.count,
        active_sessions: assessment.onboarding_sessions.in_progress.count,
        completed_sessions: assessment.onboarding_sessions.completed.count,
        question_count: assessment.questions_count_for_domain(self)
      }
    end
  end

  # Get total onboarding sessions affected by this domain
  def total_affected_sessions
    assessment_ids = assessments.pluck(:id)
    return 0 if assessment_ids.empty?

    OnboardingSession.where(assessment_id: assessment_ids).count
  end

  # Get active onboarding sessions affected
  def active_affected_sessions
    assessment_ids = assessments.pluck(:id)
    return 0 if assessment_ids.empty?

    OnboardingSession.where(assessment_id: assessment_ids).in_progress.count
  end

  # Get completed onboarding sessions affected
  def completed_affected_sessions
    assessment_ids = assessments.pluck(:id)
    return 0 if assessment_ids.empty?

    OnboardingSession.where(assessment_id: assessment_ids).completed.count
  end

  # Check if domain modifications would affect any sessions
  def has_active_usage?
    total_affected_sessions > 0
  end

  # Get impact summary
  def impact_summary
    {
      total_assessments: assessments.count,
      total_sessions: total_affected_sessions,
      active_sessions: active_affected_sessions,
      completed_sessions: completed_affected_sessions,
      child_profiles_count: child_profiles.count,
      has_active_usage: has_active_usage?
    }
  end
end
