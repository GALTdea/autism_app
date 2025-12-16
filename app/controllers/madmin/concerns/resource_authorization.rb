module Madmin
  module ResourceAuthorization
    extend ActiveSupport::Concern

    included do
      before_action :authorize_resource_action, except: [:index]
      before_action :authorize_index_action, only: [:index]
    end

    private

    def authorize_resource_action
      # Get the resource from instance variable (set by Madmin's ResourceController)
      # or find it using the model class and params[:id]
      resource = instance_variable_get(:@resource) || find_resource_by_id
      authorize [:madmin, resource] if resource
    end

    def authorize_index_action
      model_class = resource_model_class
      authorize [:madmin, model_class] if model_class
    end

    def find_resource_by_id
      return nil unless params[:id].present?

      model_class = resource_model_class
      return nil unless model_class

      model_class.find_by(id: params[:id])
    end

    def resource_model_class
      # Extract model class from controller name
      # e.g., UsersController -> User
      controller_name = self.class.name.demodulize
      model_name = controller_name.sub("Controller", "").singularize
      model_name.constantize
    rescue NameError
      nil
    end
  end
end
