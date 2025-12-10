class ChildMembershipPolicy < ApplicationPolicy
  def show?
    has_membership_for_child? || is_primary_for_child?
  end

  def create?
    # Only primary caregiver can invite others
    is_primary_for_child? || user.admin? || user.super_admin?
  end

  def update?
    # Only primary caregiver can change roles
    is_primary_for_child? || user.super_admin?
  end

  def destroy?
    # Only primary caregiver can remove memberships
    is_primary_for_child? || user.super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can see memberships for children they have access to
      if user.present?
        scope.joins(:child_profile)
             .joins('INNER JOIN child_memberships AS user_memberships ON user_memberships.child_profile_id = child_profiles.id')
             .where(user_memberships: { user_id: user.id })
      else
        scope.none
      end
    end
  end

  private

  def has_membership_for_child?
    return false unless user.present?

    ChildMembership.exists?(
      user: user,
      child_profile: record.child_profile
    )
  end

  def is_primary_for_child?
    return false unless user.present?

    ChildMembership.exists?(
      user: user,
      child_profile: record.child_profile,
      is_primary: true
    )
  end
end
