class Question < ApplicationRecord
  # Associations
  belongs_to :profile_domain
  has_many :question_options, -> { order(:position) }, dependent: :destroy
  has_many :answers, dependent: :destroy

  # Enums
  enum :response_type, {
    scale: 'scale',
    multi_choice: 'multi_choice',
    text: 'text'
  }

  # Validations
  validates :code, presence: true, uniqueness: true, format: {
    with: /\A[A-Z0-9_]+\z/,
    message: "must contain only uppercase letters, numbers, and underscores (e.g., COMM_1, SOCIAL_2)"
  }
  validates :text, presence: true
  validates :response_type, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :ordered, -> { order(:position) }
  scope :for_domain, ->(domain) { where(domain: domain) }
end
