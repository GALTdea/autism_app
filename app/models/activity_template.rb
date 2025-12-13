class ActivityTemplate < ApplicationRecord
  # Associations
  belongs_to :primary_target, class_name: "ProfileDomain", foreign_key: "primary_target_id"
  has_many :activity_logs, dependent: :destroy

  # Enums
  enum :language_level_required, {
    pre_verbal: "pre_verbal",
    single_words: "single_words",
    short_phrases: "short_phrases",
    sentences: "sentences"
  }

  enum :motor_demands, {
    low: "low",
    medium: "medium",
    high: "high"
  }

  enum :energy_level, {
    calming: "calming",
    neutral: "neutral",
    energizing: "energizing"
  }

  enum :materials_category, {
    household: "household",
    toys: "toys",
    craft: "craft",
    not_needed: "not_needed"
  }

  # Validations
  validates :title, presence: true
  validates :duration_minutes, inclusion: { in: [ 5, 10 ] }
  validates :difficulty_level, inclusion: { in: 1..5 }
  validates :age_bands, presence: true
  validates :primary_target_id, presence: true
  validates :materials, presence: true
  validates :parent_script, presence: true
  validates :variation, presence: true

  # JSON validations (lightweight)
  validate :age_bands_is_array
  validate :target_tags_is_array
  validate :contexts_is_array

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_age, ->(age) { where("json_extract(age_bands, '$') LIKE ?", "%#{age_band_for_age(age)}%") }
  scope :for_duration, ->(minutes) { where(duration_minutes: minutes) }
  scope :for_difficulty, ->(max_level) { where("difficulty_level <= ?", max_level) }
  scope :for_energy_level, ->(level) { where(energy_level: level) }

  # Helper methods
  def self.age_band_for_age(age)
    case age
    when 3..5 then "3-5"
    when 6..8 then "6-8"
    when 9..11 then "9-11"
    else nil
    end
  end

  def script_for_level(language_level)
    return parent_script unless scripts_by_level.present?
    scripts_by_level[language_level.to_s] || parent_script
  end

  def matches_target_tags?(goal_tags)
    return false if target_tags.blank? || goal_tags.blank?
    tags = ensure_array(target_tags)
    goal_tags_array = ensure_array(goal_tags)
    (tags & goal_tags_array).any?
  end

  def secondary_target_ids_array
    ensure_array(secondary_target_ids)
  end

  def age_bands_array
    ensure_array(age_bands)
  end

  def contexts_array
    ensure_array(contexts)
  end

  def sensory_profile_tags_array
    ensure_array(sensory_profile_tags)
  end

  private

  def ensure_array(value)
    return [] if value.blank?
    return value if value.is_a?(Array)
    # Handle JSON string from SQLite
    return JSON.parse(value) if value.is_a?(String)
    # Fallback: try to convert to array
    Array(value)
  rescue JSON::ParserError
    []
  end

  def age_bands_is_array
    errors.add(:age_bands, "must be an array") unless age_bands.is_a?(Array)
  end

  def target_tags_is_array
    errors.add(:target_tags, "must be an array") unless target_tags.is_a?(Array)
  end

  def contexts_is_array
    errors.add(:contexts, "must be an array") unless contexts.is_a?(Array)
  end
end
