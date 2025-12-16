module Madmin
  class ApplicationPolicy < ::ApplicationPolicy
    def index?
      user.admin? || user.super_admin?
    end

    def show?
      user.admin? || user.super_admin?
    end

    def create?
      user.admin? || user.super_admin?
    end

    def new?
      create?
    end

    def update?
      user.admin? || user.super_admin?
    end

    def edit?
      update?
    end

    def destroy?
      user.super_admin? # Only super_admin can destroy
    end

    class Scope < ::ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.super_admin?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
