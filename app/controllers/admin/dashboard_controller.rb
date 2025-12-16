module Admin
  class DashboardController < Admin::ApplicationController
    def index
      @stats = {
        total_users: User.count,
        admin_users: User.where(role: [:admin, :super_admin]).count,
        total_children: ChildProfile.count,
        active_onboardings: OnboardingSession.where(status: 'in_progress').count,
        completed_onboardings: OnboardingSession.where(status: 'completed').count,
        total_assessments: Assessment.count,
        active_assessments: Assessment.active.count,
        total_activity_logs: ActivityLog.count,
        recent_logs: ActivityLog.where('created_at >= ?', 7.days.ago).count
      }

      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_completions = OnboardingSession.where(status: 'completed').order(updated_at: :desc).limit(5).includes(:child_profile, :user)
    end
  end
end
