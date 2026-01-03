module Admin
  class QuestionPolicy < ApplicationPolicy
    def index?
      user.admin? || user.super_admin?
    end

    def show?
      user.admin? || user.super_admin?
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
