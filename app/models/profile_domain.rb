class ProfileDomain < ApplicationRecord
  # NOTE: Questions no longer belong directly to ProfileDomain.
  # They belong to AssessmentDomain. ProfileDomain is now only a semantic reference
  # used by child profiles, goals, and for organizing assessment sections.

  # Associations
  # REMOVED: has_many :questions (questions now belong to assessment_domains)
  has_many :child_domain_profiles, dependent: :destroy
  has_many :child_profiles, through: :child_domain_profiles
  has_many :child_goals, dependent: :destroy
  has_many :assessment_domains, dependent: :destroy
  has_many :assessments, through: :assessment_domains
  # Questions are accessed through assessment_domains: assessment_domains.flat_map(&:questions)

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :label, presence: true

  # Scopes
  scope :ordered, -> { order(:label) }

  # Validation Helpers

  # Check if domain has any questions (through assessment_domains)
  def has_questions?
    assessment_domains.joins(:questions).exists?
  end

  # Check if domain can be safely deleted
  # Returns false if domain is being used in:
  # - Assessments (through assessment_domains)
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

  # Get validation status with details
  # Note: Question validation is now done at the assessment_domain level, not profile_domain
  def validation_status
    {
      has_questions: has_questions?,
      can_be_deleted: can_be_deleted?,
      deletion_blockers: deletion_blockers,
      assessment_count: assessments.count,
      child_profile_count: child_profiles.count
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
