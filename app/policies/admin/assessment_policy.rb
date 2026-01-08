module Admin
  class AssessmentPolicy < ApplicationPolicy
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
      # Only super_admin can delete assessments, and only if no sessions exist
      return false unless user.super_admin?
      return false if record.has_active_sessions? || record.has_completed_sessions?
      true
    end

    # Wizard actions - all require update permissions
    def select_domains?
      update?
    end

    def update_domains?
      update?
    end

    def order_domains?
      update?
    end

    def reorder_domains?
      update?
    end

    def preview?
      update?
    end

    def clone?
      create?
    end

    def configure_scoring?
      update?
    end

    def clone_domain_for_assessment?
      update?
    end

    class Scope < ApplicationPolicy::Scope
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
