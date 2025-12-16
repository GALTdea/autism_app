module Madmin
  class ApplicationController < Madmin::BaseController
    include Pundit::Authorization
    include ResourceAuthorization

    layout "admin"

    before_action :authenticate_user!
    before_action :ensure_admin

    # Rescue from Pundit authorization errors
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def ensure_admin
      unless current_user&.admin? || current_user&.super_admin?
        flash[:alert] = "You must be an admin to access this section."
        redirect_to root_path
      end
    end

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referer || madmin_root_path)
    end
  end
end
