class Assessment < ApplicationRecord
  # Associations
  has_many :assessment_domains, dependent: :destroy
  has_many :profile_domains, through: :assessment_domains
  has_many :onboarding_sessions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :version, presence: true
  validates :name, uniqueness: { scope: :version }

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

  # Scoring configuration methods
  def scoring_config
    super || {}
  end

  def scoring_method
    scoring_config['scoring_method'] || 'average'
  end

  def level_thresholds
    scoring_config['level_thresholds'] || default_level_thresholds
  end

  def domain_overrides
    scoring_config['domain_overrides'] || {}
  end

  def extraction_rules
    scoring_config['extraction_rules'] || {}
  end

  # Helper to get scoring method for a specific domain
  def scoring_method_for_domain(domain_key)
    domain_overrides.dig(domain_key.to_s, 'scoring_method') || scoring_method
  end

  # Helper to get question weights for a domain
  def question_weights_for_domain(domain_key)
    domain_overrides.dig(domain_key.to_s, 'question_weights') || {}
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

  def default_level_thresholds
    {
      '0' => { 'min' => 0.0, 'max' => 1.0 },
      '1' => { 'min' => 1.0, 'max' => 2.0 },
      '2' => { 'min' => 2.0, 'max' => 3.0 },
      '3' => { 'min' => 3.0, 'max' => 4.0 },
      '4' => { 'min' => 4.0, 'max' => 5.0 }
    }
  end
end
