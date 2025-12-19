class ActivityLoggingService
  class Error < StandardError; end

  def self.log_activity(child_profile, activity_template, params)
    new(child_profile, activity_template, params).log
  end

  def initialize(child_profile, activity_template, params)
    @child_profile = child_profile
    @activity_template = activity_template
    @params = params
  end

  def log
    ActivityLog.create!(
      child_profile: @child_profile,
      activity_template: @activity_template,
      occurred_at: @params[:occurred_at] || Time.current,
      completed: @params[:completed],
      enjoyment: @params[:enjoyment],
      note: @params[:note]
    )
  end
end



