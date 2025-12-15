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
end
