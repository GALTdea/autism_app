class QuestionOption < ApplicationRecord
  # Associations
  belongs_to :question
  has_many :answers, dependent: :nullify

  # Validations
  validates :label, presence: true
  validates :value, presence: true, numericality: { only_integer: true }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :ordered, -> { order(:position) }
end
