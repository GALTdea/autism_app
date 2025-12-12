class ActivityTemplatesController < ApplicationController
  before_action :authenticate_user!

  def index
    @activity_templates = ActivityTemplate.active.order(:position, :title)
  end

  def show
    @activity_template = ActivityTemplate.find(params[:id])
  end
end
