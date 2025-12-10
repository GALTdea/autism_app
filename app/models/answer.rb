class Answer < ApplicationRecord
  # Associations
  belongs_to :onboarding_session
  belongs_to :question
  belongs_to :question_option, optional: true

  # Validations
  validate :has_answer_data
  validate :question_option_matches_question

  # Scopes
  scope :for_question, ->(question_id) { where(question_id: question_id) }
  scope :with_numeric_value, -> { where.not(numeric_value: nil) }
  scope :with_text, -> { where.not(free_text: [nil, '']) }

  private

  def has_answer_data
    return if question_option_id.present? || numeric_value.present? || free_text.present?

    errors.add(:base, 'must have either a question option, numeric value, or free text')
  end

  def question_option_matches_question
    return unless question_option_id.present? && question_id.present?
    return if question_option.question_id == question_id

    errors.add(:question_option, 'must belong to the same question')
  end
end
