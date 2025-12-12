class ActivityLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile
  before_action :authorize_child_profile

  def create
    activity_template = ActivityTemplate.find(params[:activity_template_id])

    ActivityLoggingService.log_activity(
      @child_profile,
      activity_template,
      activity_log_params
    )

    redirect_to child_profile_activities_path(@child_profile),
                notice: "Activity logged successfully!"
  rescue StandardError => e
    redirect_to activity_template_path(activity_template),
                alert: "Failed to log activity: #{e.message}"
  end

  def index
    @activity_logs = @child_profile.activity_logs
      .includes(:activity_template)
      .recent
      .limit(50)
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:child_profile_id])
  end

  def authorize_child_profile
    authorize @child_profile, :show?
  end

  def activity_log_params
    permitted = params.require(:activity_log).permit(
      :occurred_at,
      :completed,
      :enjoyment,
      :note
    )
    # Convert completed string to boolean
    permitted[:completed] = permitted[:completed] == "1" || permitted[:completed] == true
    permitted
  end
end
