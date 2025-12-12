class ActivityRecommendationService
  class Error < StandardError; end

  def self.recommend_for_today(child_profile)
    new(child_profile).recommend_for_today
  end

  def self.compute_and_cache(child_profile, date = Date.current)
    new(child_profile).compute_and_cache(date)
  end

  def initialize(child_profile)
    @child_profile = child_profile
  end

  def recommend_for_today
    recommendation = DailyRecommendation.for_today.find_by(child_profile: @child_profile)

    if recommendation&.expired? || recommendation.nil?
      compute_and_cache(Date.current)
      recommendation = DailyRecommendation.for_today.find_by(child_profile: @child_profile)
    end

    recommendation&.activities || []
  end

  def compute_and_cache(date)
    activities = compute_recommendations

    DailyRecommendation.find_or_initialize_by(
      child_profile: @child_profile,
      date: date
    ).update!(
      activity_template_ids: activities.map(&:id),
      computed_at: Time.current
    )

    activities
  end

  private

  def compute_recommendations
    # Step 1: Filter
    candidates = filter_activities

    # Step 2: Score
    scored = score_activities(candidates)

    # Step 3: Select 3
    select_recommendations(scored)
  end

  def filter_activities
    activities = ActivityTemplate.active

    # Age band
    if age_band = @child_profile.age_band
      # SQLite JSON querying is limited, so we'll filter in Ruby for now
      activities = activities.select do |activity|
        activity.age_bands.include?(age_band)
      end
    end

    # Contexts
    if contexts = @child_profile.preferred_contexts.presence
      activities = activities.select do |activity|
        (activity.contexts & contexts).any?
      end
    else
      # Default to home if no preferences set
      activities = activities.select do |activity|
        activity.contexts.include?("home")
      end
    end

    # Sensory fit (exclude no-gos)
    sensory_profile = @child_profile.sensory_profile
    if sensory_profile
      sensitivity_tags = sensory_profile[:sensitivity_tags] || []

      # Exclude activities that conflict with sensory avoidances
      if sensitivity_tags.include?("avoids_loud_noise")
        activities = activities.reject do |activity|
          activity.sensory_profile_tags&.include?("loud_noise")
        end
      end
    end

    # Difficulty (exclude activities far above child's level)
    # For now, we'll use a simple heuristic based on average domain level
    avg_level = @child_profile.child_domain_profiles.average(:level_estimate).to_f
    max_difficulty = [ avg_level.to_i + 2, 5 ].min
    activities = activities.select do |activity|
      activity.difficulty_level <= max_difficulty
    end

    activities
  end

  def score_activities(candidates)
    top_goals = @child_profile.top_goals(2)
    goal_domains = top_goals.map(&:profile_domain_id)
    goal_tags = top_goals.flat_map { |g| g.target_tags || [] }.uniq
    language_profile = @child_profile.language_profile

    candidates.map do |activity|
      score = 0

      # Goal matching (domain + tag overlap)
      if goal_domains.include?(activity.primary_target_id)
        score += 2
        # Bonus for tag overlap
        if activity.matches_target_tags?(goal_tags)
          score += 1
        end
      end

      if (activity.secondary_target_ids & goal_domains).any?
        score += 1
      end

      # Language level
      if language_fits?(activity, language_profile)
        score += 1
      end

      # Context priority (if activity matches preferred contexts)
      if context_priority_match?(activity)
        score += 1
      end

      # Recent enjoyment (will be implemented in Phase 2c)
      # For now, skip this scoring

      # Recency penalty (will be implemented in Phase 2c)
      # For now, skip this scoring

      { activity: activity, score: score }
    end.sort_by { |item| -item[:score] }
  end

  def select_recommendations(scored)
    return [] if scored.empty?

    recommendations = []

    # 1. Anchor Favorite - high score, prefer activities with good fit
    anchor = scored.first
    recommendations << anchor[:activity] if anchor

    # 2. Goal-Focused Stretch - matches goals, not the anchor
    goal_focused = scored.find do |item|
      item[:activity] != anchor[:activity] && item[:score] > 0
    end
    recommendations << goal_focused[:activity] if goal_focused

    # 3. Novelty Option - new or different from first two
    novelty = scored.find do |item|
      !recommendations.include?(item[:activity])
    end
    recommendations << novelty[:activity] if novelty

    # Ensure we have exactly 3 (or fewer if not enough candidates)
    recommendations.first(3)
  end

  def language_fits?(activity, language_profile)
    return true unless language_profile && activity.language_level_required

    language_levels = {
      "pre_verbal" => 0,
      "single_words" => 1,
      "short_phrases" => 2,
      "sentences" => 3
    }

    # Use expressive level for matching (can use receptive as fallback)
    child_level = language_profile[:expressive_level] || language_profile[:receptive_level]
    return true unless child_level

    required_level = language_levels[activity.language_level_required]
    child_level_value = language_levels[child_level]

    child_level_value >= required_level
  end

  def context_priority_match?(activity)
    contexts = @child_profile.preferred_contexts.presence || [ "home" ]
    (activity.contexts & contexts).any?
  end
end
