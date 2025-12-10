class OnboardingSessionPolicy < ApplicationPolicy
  def start?
    has_membership_for_child? && is_parent_or_primary?
  end

  def show?
    has_membership_for_child? || is_session_owner?
  end

  def create?
    has_membership_for_child? && is_parent_or_primary?
  end

  def update?
    is_session_owner? || is_primary_for_child?
  end

  def complete?
    is_session_owner? || is_primary_for_child?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can see onboarding sessions for children they have access to
      if user.present?
        scope.joins(:child_profile)
             .joins('INNER JOIN child_memberships ON child_memberships.child_profile_id = child_profiles.id')
             .where(child_memberships: { user_id: user.id })
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

  def is_session_owner?
    return false unless user.present?

    record.user_id == user.id
  end

  def is_primary_for_child?
    return false unless user.present?

    ChildMembership.exists?(
      user: user,
      child_profile: record.child_profile,
      is_primary: true
    )
  end

  def is_parent_or_primary?
    return false unless user.present?

    membership = ChildMembership.find_by(
      user: user,
      child_profile: record.child_profile
    )

    return false unless membership

    membership.parent? || membership.is_primary?
  end
end
