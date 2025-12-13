class ActivityLog < ApplicationRecord
  # Associations
  belongs_to :child_profile
  belongs_to :activity_template

  # Enums
  enum :enjoyment, {
    thumbs_down: 0,
    neutral: 1,
    thumbs_up: 2
  }

  # Validations
  validates :occurred_at, presence: true
  validates :completed, inclusion: { in: [ true, false ] }
  validates :enjoyment, presence: true

  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :for_date_range, ->(start_date, end_date) {
    where(occurred_at: start_date.beginning_of_day..end_date.end_of_day)
  }
  scope :recent, -> { order(occurred_at: :desc) }

  # Class methods
  def self.average_enjoyment_for_activity(activity_template_id)
    where(activity_template_id: activity_template_id)
      .average(:enjoyment)
      .to_f
  end

  def self.completion_rate_for_activity(activity_template_id)
    logs = where(activity_template_id: activity_template_id)
    return 0.0 if logs.empty?
    logs.where(completed: true).count.to_f / logs.count
  end

  def self.recent_logs_for_activity(child_profile, activity_template, limit: 3)
    where(child_profile: child_profile, activity_template: activity_template)
      .recent
      .limit(limit)
  end

  def self.used_recently?(child_profile, activity_template, days: 2)
    where(
      child_profile: child_profile,
      activity_template: activity_template
    )
      .where("occurred_at > ?", days.days.ago)
      .exists?
  end
end
