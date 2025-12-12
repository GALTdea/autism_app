class ChildDomainProfile < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :profile_domain

  # Enums (for communication domain)
  enum :expressive_level, {
    pre_verbal: "pre_verbal",
    single_words: "single_words",
    short_phrases: "short_phrases",
    sentences: "sentences"
  }, prefix: "expressive"

  enum :receptive_level, {
    pre_verbal: "pre_verbal",
    single_words: "single_words",
    short_phrases: "short_phrases",
    sentences: "sentences"
  }, prefix: "receptive"

  # Validations
  validates :level_estimate, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :profile_domain_id, uniqueness: { scope: :child_profile_id }
  validate :supports_is_array, if: -> { supports.present? }
  validate :sensitivity_tags_is_array, if: -> { sensitivity_tags.present? }

  # Scopes
  scope :ordered, -> { joins(:profile_domain).order("profile_domains.label") }
  scope :by_level, -> { order(:level_estimate) }

  private

  def supports_is_array
    errors.add(:supports, "must be an array") unless supports.is_a?(Array)
  end

  def sensitivity_tags_is_array
    errors.add(:sensitivity_tags, "must be an array") unless sensitivity_tags.is_a?(Array)
  end
end
