class AssessmentDomain < ApplicationRecord
  # NOTE: AssessmentDomain can now exist in two states:
  # 1. Standalone - Created independently, can be added to assessments later
  # 2. In-Assessment - Part of a specific assessment version
  #
  # When standalone: assessment_id is NULL, name/version required
  # When in-assessment: assessment_id is NOT NULL, position required
  # profile_domain_id is optional in both cases (can be set later for semantic reference)

  # Associations
  belongs_to :assessment, optional: true
  belongs_to :profile_domain, optional: true  # Semantic reference for child profiles/goals

  # Questions belong to AssessmentDomain
  has_many :questions, dependent: :destroy

  # Validations
  # Name is required when standalone
  validates :name, presence: true, if: -> { assessment_id.nil? }

  # Position is required when in an assessment
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                       if: -> { assessment_id.present? }

  # Uniqueness: profile_domain must be unique per assessment (only when in assessment)
  # Database enforces this via partial unique index, but we validate for better error messages
  validate :unique_profile_domain_per_assessment, if: -> { assessment_id.present? && profile_domain_id.present? }

  # Uniqueness: name + version must be unique for standalone domains
  # Database enforces this via partial unique index, but we validate for better error messages
  validate :unique_name_version_for_standalone, if: -> { assessment_id.nil? && name.present? }

  # Scopes
  scope :ordered, -> { order(Arel.sql("COALESCE(position, 999999)"), :name) }  # Standalone domains sorted by name, in-assessment by position
  scope :standalone, -> { where(assessment_id: nil) }
  scope :in_assessments, -> { where.not(assessment_id: nil) }

  # State check methods
  def standalone?
    assessment_id.nil?
  end

  def in_assessment?
    assessment_id.present?
  end

  # Helper methods

  # Get the domain key for semantic reference
  # Falls back to name-based key if profile_domain is not set
  def domain_key
    if profile_domain.present?
      profile_domain.key
    elsif name.present?
      # Generate a key from name (for standalone domains without profile_domain)
      name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
    else
      nil
    end
  end

  # Get the domain label for display
  # Falls back to name if profile_domain is not set
  def domain_label
    if profile_domain.present?
      profile_domain.label
    elsif name.present?
      name
    else
      "Unnamed Domain"
    end
  end

  # Get display name (prefers name, then profile_domain label, then fallback)
  def display_name
    name.presence || profile_domain&.label || "Unnamed Domain"
  end

  # Question count
  def question_count
    questions.count
  end

  # Check if section has questions
  def has_questions?
    questions.any?
  end

  # Add this domain to an assessment
  # Moves from standalone to in-assessment state
  def add_to_assessment(assessment, profile_domain: nil, position: nil)
    raise ArgumentError, "Assessment is required" if assessment.nil?
    raise ArgumentError, "Domain is already in an assessment" if in_assessment?

    position ||= assessment.assessment_domains.maximum(:position).to_i + 1
    profile_domain ||= self.profile_domain

    update!(
      assessment: assessment,
      profile_domain: profile_domain,
      position: position
    )
  end

  # Remove from assessment (becomes standalone)
  # Note: This will keep the questions but remove the assessment association
  def remove_from_assessment
    raise ArgumentError, "Domain is not in an assessment" unless in_assessment?

    update!(
      assessment: nil,
      position: nil
      # Keep profile_domain and name for context
    )
  end

  # Clone this domain (can be standalone or in-assessment)
  # assessment: nil means make it standalone, :keep_original (default) means keep original assessment
  def clone(new_name: nil, new_version: nil, assessment: :keep_original)
    new_name ||= "#{name} (Copy)" if name.present?
    new_version ||= version

    # Determine assessment: if :keep_original, use self.assessment; otherwise use provided (can be nil for standalone)
    cloned_assessment = (assessment == :keep_original) ? self.assessment : assessment

    cloned = AssessmentDomain.create!(
      assessment: cloned_assessment,
      profile_domain: profile_domain,
      name: new_name,
      version: new_version,
      description: description,
      position: cloned_assessment ? nil : position
    )

    # Clone questions
    questions.each do |question|
      Question.create!(
        assessment_domain: cloned,
        code: question.code,
        text: question.text,
        domain: question.domain,
        response_type: question.response_type,
        position: question.position
      ).tap do |cloned_question|
        # Clone question options
        question.question_options.each do |option|
          cloned_question.question_options.create!(
            label: option.label,
            value: option.value,
            position: option.position
          )
        end
      end
    end

    cloned
  end

  private

  def unique_profile_domain_per_assessment
    existing = AssessmentDomain.where(assessment_id: assessment_id, profile_domain_id: profile_domain_id)
                              .where.not(id: id)
    if existing.exists?
      errors.add(:profile_domain_id, "has already been added to this assessment")
    end
  end

  def unique_name_version_for_standalone
    existing = AssessmentDomain.where(assessment_id: nil, name: name, version: version)
                              .where.not(id: id)
    if existing.exists?
      errors.add(:name, "and version combination already exists for standalone domains")
    end
  end
end
