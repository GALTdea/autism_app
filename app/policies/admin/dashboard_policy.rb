module Admin
  class DashboardPolicy < ApplicationPolicy
    def index?
      user.admin? || user.super_admin?
    end
  end
end
