module Admin
  class ProfileDomainPolicy < ApplicationPolicy
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
      # Only super_admin can delete profile domains
      # The controller will check if domain can be deleted (not in use)
      user.super_admin?
    end

    # Builder actions
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
