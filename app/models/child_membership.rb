class ChildMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :child_profile

  # Enums
  enum :role, {
    parent: 'parent',
    therapist: 'therapist',
    co_parent: 'co_parent',
    caregiver: 'caregiver'
  }

  # Validations
  validates :role, presence: true
  validates :is_primary, inclusion: { in: [true, false] }
  validate :only_one_primary_per_child

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :for_role, ->(role) { where(role: role) }

  private

  def only_one_primary_per_child
    return unless is_primary?

    existing_primary = ChildMembership
                        .where(child_profile_id: child_profile_id, is_primary: true)
                        .where.not(id: id)

    return unless existing_primary.exists?

    errors.add(:is_primary, 'only one primary caregiver allowed per child')
  end
end
