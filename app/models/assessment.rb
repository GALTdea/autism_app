class Assessment < ApplicationRecord
  # Associations
  has_many :assessment_domains, dependent: :destroy # or assessment_sections
  has_many :profile_domains, through: :assessment_domains
  has_many :questions, through: :assessment_domains  # Questions now belong to assessment_domains
  has_many :onboarding_sessions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :version, presence: true
  validates :name, uniqueness: { scope: :version }

  # Callbacks
  before_save :ensure_single_default, if: -> { is_default? && (is_default_changed? || new_record?) }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :default, -> { where(is_default: true) }
  scope :ordered, -> { order(:name, :version) }

  # Instance methods
  def activate!
    # Deactivate all other assessments
    Assessment.update_all(is_default: false)
    update(is_default: true, active: true)
  end

  def deactivate!
    update(active: false, is_default: false)
  end

  # Add a domain to this assessment
  # Accepts either ProfileDomain (creates new AssessmentDomain) or AssessmentDomain (adds standalone domain)
  def add_domain(domain, position: nil)
    position ||= assessment_domains.maximum(:position).to_i + 1

    case domain
    when ProfileDomain
      # Legacy: Create AssessmentDomain from ProfileDomain
      assessment_domains.find_or_create_by!(profile_domain: domain) do |ad|
        ad.position = position
      end
    when AssessmentDomain
      # New: Add standalone AssessmentDomain to this assessment
      raise ArgumentError, "AssessmentDomain is already in an assessment" if domain.in_assessment?
      domain.add_to_assessment(self, position: position)
      domain
    else
      raise ArgumentError, "Domain must be a ProfileDomain or AssessmentDomain"
    end
  end

  # Remove a domain from this assessment
  # Accepts either ProfileDomain or AssessmentDomain
  def remove_domain(domain)
    case domain
    when ProfileDomain
      # Legacy: Remove by ProfileDomain
      assessment_domains.where(profile_domain: domain).destroy_all
    when AssessmentDomain
      # New: Remove specific AssessmentDomain
      raise ArgumentError, "AssessmentDomain does not belong to this assessment" unless domain.assessment == self
      domain.remove_from_assessment
    else
      raise ArgumentError, "Domain must be a ProfileDomain or AssessmentDomain"
    end
  end

  # Convenience method: Add an AssessmentDomain explicitly
  def add_assessment_domain(assessment_domain, position: nil)
    add_domain(assessment_domain, position: position)
  end

  # Convenience method: Remove an AssessmentDomain explicitly
  def remove_assessment_domain(assessment_domain)
    remove_domain(assessment_domain)
  end

  def domain_count
    assessment_domains.count
  end

  # Returns ProfileDomains (for backward compatibility)
  # Filters out AssessmentDomains that don't have a profile_domain
  def ordered_domains
    profile_domains.joins(:assessment_domains)
                   .merge(AssessmentDomain.ordered)
                   .distinct
  end

  # Returns AssessmentDomains directly (preferred for new code)
  def ordered_assessment_domains
    assessment_domains.ordered
  end

  # Validation helpers
  def has_domains?
    assessment_domains.any?
  end

  def has_profile_domains?
    profile_domains.any?
  end

  def can_be_deleted?
    onboarding_sessions.empty?
  end

  def has_active_sessions?
    onboarding_sessions.in_progress.any?
  end

  def has_completed_sessions?
    onboarding_sessions.completed.any?
  end

  def is_usable?
    active? && has_domains?
  end

  def domain_included?(profile_domain)
    profile_domains.include?(profile_domain)
  end

  # Check if an AssessmentDomain belongs to this assessment
  def includes_assessment_domain?(assessment_domain)
    assessment_domains.include?(assessment_domain)
  end

  # Query methods for questions
  # Questions now belong to assessment_domains, not profile_domains
  def questions_for_domain(profile_domain)
    return Question.none unless domain_included?(profile_domain)
    assessment_domain = assessment_domains.find_by(profile_domain: profile_domain)
    return Question.none unless assessment_domain
    assessment_domain.questions.ordered
  end

  # Get questions for an AssessmentDomain directly
  def questions_for_assessment_domain(assessment_domain)
    return Question.none unless includes_assessment_domain?(assessment_domain)
    assessment_domain.questions.ordered
  end

  def questions_for_domain_by_key(domain_key)
    domain = profile_domains.find_by(key: domain_key)
    return Question.none unless domain
    questions_for_domain(domain)
  end

  # Get questions for AssessmentDomain by its domain_key (handles both profile_domain and name-based keys)
  def questions_for_assessment_domain_by_key(domain_key)
    assessment_domain = assessment_domains.find { |ad| ad.domain_key == domain_key.to_s }
    return Question.none unless assessment_domain
    assessment_domain.questions.ordered
  end

  def total_questions_count
    questions.count
  end

  def questions_count_for_domain(profile_domain)
    return 0 unless domain_included?(profile_domain)
    assessment_domain = assessment_domains.find_by(profile_domain: profile_domain)
    return 0 unless assessment_domain
    assessment_domain.questions.count
  end

  # Get question count for an AssessmentDomain directly
  def questions_count_for_assessment_domain(assessment_domain)
    return 0 unless includes_assessment_domain?(assessment_domain)
    assessment_domain.questions.count
  end

  def questions_in_order
    # Returns all questions from all assessment_domains, ordered by domain position, then question position
    Question.joins(:assessment_domain)
            .where(assessment_domains: { assessment_id: id })
            .merge(AssessmentDomain.ordered)
            .order("assessment_domains.position ASC, questions.position ASC")
  end

  # Returns domains with question counts (ProfileDomain-based, for backward compatibility)
  def domains_with_question_counts
    ordered_domains.map do |domain|
      assessment_domain = assessment_domains.find_by(profile_domain: domain)
      {
        domain: domain,
        question_count: assessment_domain&.question_count || 0,
        position: assessment_domain&.position
      }
    end
  end

  # Returns AssessmentDomains with question counts (preferred for new code)
  def assessment_domains_with_question_counts
    ordered_assessment_domains.map do |assessment_domain|
      {
        assessment_domain: assessment_domain,
        profile_domain: assessment_domain.profile_domain,
        question_count: assessment_domain.question_count,
        position: assessment_domain.position,
        domain_key: assessment_domain.domain_key,
        domain_label: assessment_domain.domain_label
      }
    end
  end

  # Clone helper method (delegates to service)
  def clone(new_name: nil, new_version: nil)
    AssessmentCloningService.clone(self, new_name: new_name, new_version: new_version)
  end

  # Scoring configuration methods
  def scoring_config
    super || {}
  end

  def scoring_method
    scoring_config["scoring_method"] || "average"
  end

  def level_thresholds
    scoring_config["level_thresholds"] || default_level_thresholds
  end

  def domain_overrides
    scoring_config["domain_overrides"] || {}
  end

  def extraction_rules
    scoring_config["extraction_rules"] || {}
  end

  # Helper to get scoring method for a specific domain
  def scoring_method_for_domain(domain_key)
    domain_overrides.dig(domain_key.to_s, "scoring_method") || scoring_method
  end

  # Helper to get question weights for a domain
  def question_weights_for_domain(domain_key)
    domain_overrides.dig(domain_key.to_s, "question_weights") || {}
  end

  # Helper to get extraction rules for a domain
  def extraction_rules_for_domain(domain_key)
    extraction_rules[domain_key.to_s] || {}
  end

  # Update scoring config by deep merging
  def update_scoring_config(config_hash)
    update(scoring_config: scoring_config.deep_merge(config_hash))
  end

  private

  def ensure_single_default
    # If this assessment is being set as default, unset all others
    if persisted?
      Assessment.where.not(id: id).update_all(is_default: false)
    else
      # For new records, update all existing assessments
      Assessment.update_all(is_default: false)
    end
  end

  def default_level_thresholds
    {
      "0" => { "min" => 0.0, "max" => 1.0 },
      "1" => { "min" => 1.0, "max" => 2.0 },
      "2" => { "min" => 2.0, "max" => 3.0 },
      "3" => { "min" => 3.0, "max" => 4.0 },
      "4" => { "min" => 4.0, "max" => 5.0 }
    }
  end
end
