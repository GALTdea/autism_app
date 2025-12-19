class AssessmentDomain < ApplicationRecord
  # Associations
  belongs_to :assessment
  belongs_to :profile_domain

  # Validations
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :profile_domain_id, uniqueness: { scope: :assessment_id }

  # Scopes
  scope :ordered, -> { order(:position) }
end


