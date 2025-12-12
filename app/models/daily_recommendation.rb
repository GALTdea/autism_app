class DailyRecommendation < ApplicationRecord
  # Associations
  belongs_to :child_profile

  # Validations
  validates :date, presence: true
  validates :activity_template_ids, presence: true
  validates :child_profile_id, uniqueness: { scope: :date }
  validate :activity_template_ids_is_array

  # Scopes
  scope :for_date, ->(date) { where(date: date) }
  scope :for_today, -> { for_date(Date.current) }
  scope :recent, -> { order(date: :desc) }

  # Instance methods
  def activities
    ActivityTemplate.where(id: activity_template_ids)
  end

  def anchor_favorite
    activities.find_by(id: activity_template_ids[0])
  end

  def goal_focused_stretch
    activities.find_by(id: activity_template_ids[1])
  end

  def novelty_option
    activities.find_by(id: activity_template_ids[2])
  end

  def expired?
    date < Date.current
  end

  private

  def activity_template_ids_is_array
    errors.add(:activity_template_ids, "must be an array") unless activity_template_ids.is_a?(Array)
  end
end
