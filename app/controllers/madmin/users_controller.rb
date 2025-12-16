module Madmin
  class UsersController < Madmin::ResourceController
    # Add authorization checks using before_action callbacks
    # Note: We hook into Madmin's flow by setting instance variables that
    # Madmin's ResourceController will use, then authorize them
    before_action :authorize_resource, except: [:index]
    before_action :authorize_index, only: [:index]

    private

    def authorize_resource
      # Madmin sets @resource or we can find it from params
      resource = instance_variable_get(:@resource) || User.find_by(id: params[:id])
      authorize [:madmin, resource] if resource
    end

    def authorize_index
      authorize [:madmin, User]
      # Use policy scope for the index
      if respond_to?(:policy_scope, true)
        @users = policy_scope([:madmin, User])
      end
    end
  end
end
