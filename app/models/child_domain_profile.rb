class ChildDomainProfile < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :profile_domain

  # Validations
  validates :level_estimate, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :profile_domain_id, uniqueness: { scope: :child_profile_id }

  # Scopes
  scope :ordered, -> { joins(:profile_domain).order('profile_domains.label') }
  scope :by_level, -> { order(:level_estimate) }
end
