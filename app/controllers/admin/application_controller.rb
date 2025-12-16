module Admin
  class ApplicationController < ::ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :ensure_admin

    private

    def ensure_admin
      unless current_user&.admin? || current_user&.super_admin?
        flash[:alert] = "You must be an admin to access this section."
        redirect_to root_path
      end
    end
  end
end
