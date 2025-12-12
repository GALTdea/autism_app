class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile
  before_action :authorize_child_profile

  def index
    # Today's recommendations
    @recommendations = ActivityRecommendationService.recommend_for_today(@child_profile)
    @daily_recommendation = DailyRecommendation.for_today.find_by(child_profile: @child_profile)
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:child_profile_id])
  end

  def authorize_child_profile
    authorize @child_profile, :show?
  end
end
