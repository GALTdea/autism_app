module Admin
  class AssessmentDomainPolicy < ApplicationPolicy
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
      # Only super_admin can delete assessment domains
      # The controller will check if domain can be deleted (not in use in assessments)
      user.super_admin?
    end

    # Question management actions
    def manage_questions?
      update?
    end

    def create_question?
      update?
    end

    def update_question?
      update?
    end

    def destroy_question?
      update?
    end

    def reorder_questions?
      update?
    end

    def preview?
      show?
    end

    def clone?
      create?
    end

    # Question Option actions
    def create_option?
      update?
    end

    def update_option?
      update?
    end

    def destroy_option?
      update?
    end

    def reorder_options?
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
