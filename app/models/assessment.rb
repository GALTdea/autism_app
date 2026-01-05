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

  def add_domain(profile_domain, position: nil)
    position ||= assessment_domains.maximum(:position).to_i + 1
    assessment_domains.find_or_create_by!(profile_domain: profile_domain) do |ad|
      ad.position = position
    end
  end

  def remove_domain(profile_domain)
    assessment_domains.where(profile_domain: profile_domain).destroy_all
  end

  def domain_count
    profile_domains.count
  end

  def ordered_domains
    profile_domains.joins(:assessment_domains)
                   .merge(AssessmentDomain.ordered)
                   .distinct
  end

  # Validation helpers
  def has_domains?
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

  # Query methods for questions
  # Questions now belong to assessment_domains, not profile_domains
  def questions_for_domain(profile_domain)
    return Question.none unless domain_included?(profile_domain)
    assessment_domain = assessment_domains.find_by(profile_domain: profile_domain)
    return Question.none unless assessment_domain
    assessment_domain.questions.ordered
  end

  def questions_for_domain_by_key(domain_key)
    domain = profile_domains.find_by(key: domain_key)
    return Question.none unless domain
    questions_for_domain(domain)
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

  def questions_in_order
    # Returns all questions from all assessment_domains, ordered by domain position, then question position
    Question.joins(:assessment_domain)
            .where(assessment_domains: { assessment_id: id })
            .merge(AssessmentDomain.ordered)
            .order("assessment_domains.position ASC, questions.position ASC")
  end

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
