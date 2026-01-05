class AssessmentDomain < ApplicationRecord
  # NOTE: This model acts as an "Assessment Section" that owns questions.
  # It references a ProfileDomain for semantic mapping (used by child profiles/goals),
  # but questions will belong directly to AssessmentDomain, not ProfileDomain.
  # This enables true assessment versioning where each assessment has its own question sets.

  # Associations
  belongs_to :assessment
  belongs_to :profile_domain  # Semantic reference for child profiles/goals

  # Questions will belong to AssessmentDomain (to be enabled in next migration step)
  # TODO: Uncomment after migrating questions from profile_domain to assessment_domain
  # has_many :questions, dependent: :destroy

  # Validations
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :profile_domain_id, uniqueness: { scope: :assessment_id }

  # Scopes
  scope :ordered, -> { order(:position) }

  # Helper methods (will be fully functional after questions migration)

  # Get the domain key for semantic reference
  def domain_key
    profile_domain.key
  end

  # Get the domain label for display
  def domain_label
    profile_domain.label
  end

  # Question count (will work after questions migration)
  # TODO: Uncomment after migrating questions
  # def question_count
  #   questions.count
  # end

  # Check if section has questions (will work after questions migration)
  # TODO: Uncomment after migrating questions
  # def has_questions?
  #   questions.any?
  # end
end
