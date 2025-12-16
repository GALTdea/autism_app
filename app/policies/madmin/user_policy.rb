module Madmin
  class UserPolicy < ApplicationPolicy
    # All admins can update users, but role changes are restricted in controller
    def update?
      user.admin? || user.super_admin?
    end

    # Only super_admin can destroy users, and they can't delete themselves
    def destroy?
      return false unless user.super_admin?
      return false if record == user # Prevent self-deletion
      super
    end

    # All admins can create users
    def create?
      user.admin? || user.super_admin?
    end

    # Helper method to check if user can change roles (used in controller/views)
    def can_change_role?
      user.super_admin?
    end
  end
end
