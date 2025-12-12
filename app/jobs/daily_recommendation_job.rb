class DailyRecommendationJob < ApplicationJob
  queue_as :default

  def perform
    # Run daily at 6 AM to compute recommendations for all active children
    ChildProfile.active.find_each do |child_profile|
      begin
        ActivityRecommendationService.compute_and_cache(child_profile, Date.current)
      rescue StandardError => e
        # Log error but continue with other children
        Rails.logger.error "Failed to compute recommendations for child_profile #{child_profile.id}: #{e.message}"
      end
    end
  end
end
