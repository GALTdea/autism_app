class ChildProfilePolicy < ApplicationPolicy
  def show?
    has_membership?
  end

  def create?
    user.present?
  end

  def update?
    is_primary_caregiver? || user.admin? || user.super_admin?
  end

  def destroy?
    is_primary_caregiver? || user.super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see child profiles they have membership for
      if user.present?
        scope.joins(:child_memberships).where(child_memberships: { user_id: user.id })
      else
        scope.none
      end
    end
  end

  private

  def has_membership?
    return false unless user.present?

    ChildMembership.exists?(user: user, child_profile: record)
  end

  def is_primary_caregiver?
    return false unless user.present?

    ChildMembership.exists?(
      user: user,
      child_profile: record,
      is_primary: true
    )
  end
end
