class ProfileDomain < ApplicationRecord
  # Associations
  has_many :questions, dependent: :destroy
  has_many :child_domain_profiles, dependent: :destroy
  has_many :child_profiles, through: :child_domain_profiles
  has_many :child_goals, dependent: :destroy

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :label, presence: true

  # Scopes
  scope :ordered, -> { order(:label) }
end
