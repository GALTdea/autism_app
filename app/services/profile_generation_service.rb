class ProfileGenerationService
  class Error < StandardError; end

  # Template-based profile generation (Phase 1)
  # Designed to be AI-ready - can swap templates for AI later
  def self.generate_profile(child_profile, onboarding_session)
    new(child_profile, onboarding_session).generate_profile
  end

  def initialize(child_profile, onboarding_session)
    @child_profile = child_profile
    @onboarding_session = onboarding_session
  end

  def generate_profile
    # Score answers by domain
    domain_scores = calculate_domain_scores

    # Generate domain profiles
    create_domain_profiles(domain_scores)

    # Generate suggested goals
    generate_goals(domain_scores)

    # Create profile summary document
    create_profile_summary(domain_scores)

    @child_profile
  end

  private

  def calculate_domain_scores
    scores = {}

    ProfileDomain.all.each do |domain|
      domain_answers = @onboarding_session.answers
                                          .joins(question: :profile_domain)
                                          .where(profile_domains: { id: domain.id })
                                          .where.not(numeric_value: nil)

      if domain_answers.any?
        avg_score = domain_answers.average(:numeric_value).to_f
        scores[domain.key] = {
          domain: domain,
          average_score: avg_score,
          level_estimate: score_to_level(avg_score),
          answer_count: domain_answers.count
        }
      else
        scores[domain.key] = {
          domain: domain,
          average_score: 0,
          level_estimate: 0,
          answer_count: 0
        }
      end
    end

    scores
  end

  def score_to_level(score)
    # Simple mapping: 0-1 = 0, 1-2 = 1, 2-3 = 2, 3-4 = 3, 4+ = 4
    # Adjust based on your scale (assuming 0-4 or 0-5 scale)
    case score
    when 0..1 then 0
    when 1..2 then 1
    when 2..3 then 2
    when 3..4 then 3
    else 4
    end
  end

  def create_domain_profiles(domain_scores)
    domain_scores.each do |_key, data|
      next if data[:answer_count].zero?

      domain = data[:domain]
      level = data[:level_estimate]
      avg_score = data[:average_score]

      # Generate strengths and needs summaries
      strengths = generate_strengths_summary(domain, level, avg_score)
      needs = generate_needs_summary(domain, level, avg_score)

      domain_profile = ChildDomainProfile.find_or_initialize_by(
        child_profile: @child_profile,
        profile_domain: domain
      )

      domain_profile.assign_attributes(
        level_estimate: level,
        strengths_summary: strengths,
        needs_summary: needs
      )

      # Extract Phase 2 specific data
      extract_language_profile(domain_profile) if domain.key == 'communication'
      extract_sensory_profile(domain_profile) if domain.key == 'sensory'

      domain_profile.save!
    end
  end

  def extract_language_profile(domain_profile)
    # Extract expressive level from COMM_1 (How does your child communicate their needs and wants?)
    expressive_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'COMM_1' })

    if expressive_answer&.numeric_value
      expressive_level = case expressive_answer.numeric_value
      when 4 then 'sentences'
      when 3 then 'short_phrases'
      when 2 then 'single_words'
      when 0, 1 then 'pre_verbal'
      else 'single_words'
      end
      domain_profile.expressive_level = expressive_level
    end

    # Extract receptive level from COMM_3 (How well does your child understand spoken instructions?)
    receptive_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'COMM_3' })

    if receptive_answer&.numeric_value
      receptive_level = case receptive_answer.numeric_value
      when 4 then 'sentences'
      when 3 then 'short_phrases'
      when 2 then 'single_words'
      when 0, 1 then 'pre_verbal'
      else 'single_words'
      end
      domain_profile.receptive_level = receptive_level
    end

    # Extract supports from COMM_4 (Does your child use visual supports?)
    supports_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'COMM_4' })

    supports = []
    if supports_answer&.numeric_value
      if supports_answer.numeric_value >= 2
        supports << 'visual_supports'
      end
    end
    domain_profile.supports = supports if supports.any?
  end

  def extract_sensory_profile(domain_profile)
    # Extract seeking level from SENSORY_2 (Does your child seek out sensory input?)
    seeking_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'SENSORY_2' })

    if seeking_answer&.numeric_value
      # Invert scale: lower value = more seeking
      seeking_level = 4 - seeking_answer.numeric_value
      domain_profile.seeking_level = [seeking_level, 0].max
    end

    # Extract avoiding level from SENSORY_1 (How does your child respond to loud sounds?)
    avoiding_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'SENSORY_1' })

    if avoiding_answer&.numeric_value
      # Lower value = more avoiding
      avoiding_level = 4 - avoiding_answer.numeric_value
      domain_profile.avoiding_level = [avoiding_level, 0].max
    end

    # Extract sensitivity tags
    sensitivity_tags = []
    
    # Loud sounds sensitivity
    if avoiding_answer&.numeric_value && avoiding_answer.numeric_value <= 2
      sensitivity_tags << 'avoids_loud_noise'
    end

    # Texture sensitivity from SENSORY_3
    texture_answer = @onboarding_session.answers
      .joins(:question)
      .find_by(questions: { code: 'SENSORY_3' })

    if texture_answer&.numeric_value && texture_answer.numeric_value <= 2
      sensitivity_tags << 'texture_sensitivity'
    end

    # Seeking behaviors
    if seeking_answer&.numeric_value && seeking_answer.numeric_value <= 2
      sensitivity_tags << 'seeks_movement'
    end

    domain_profile.sensitivity_tags = sensitivity_tags if sensitivity_tags.any?
  end

  def generate_strengths_summary(domain, level, score)
    # Template-based strengths generation
    # In Phase 1, use simple templates. Later, replace with AI.
    if level >= 3
      "Strong performance in #{domain.label.downcase}. Shows consistent abilities in this area."
    elsif level >= 2
      "Developing skills in #{domain.label.downcase}. Shows some strengths with room for growth."
    else
      "Early stages of development in #{domain.label.downcase}."
    end
  end

  def generate_needs_summary(domain, level, score)
    # Template-based needs generation
    if level <= 1
      "Significant support needed in #{domain.label.downcase}. Focus area for intervention."
    elsif level <= 2
      "Some support needed in #{domain.label.downcase}. Continued practice and support recommended."
    else
      "Minimal support needed. Continue to build on existing strengths."
    end
  end

  def generate_goals(domain_scores)
    # Generate 3-5 suggested goals based on domain scores
    priority_domains = domain_scores.values
                                    .select { |d| d[:level_estimate] <= 2 && d[:answer_count] > 0 }
                                    .sort_by { |d| d[:level_estimate] }
                                    .first(3)

    priority_rank = 1

    priority_domains.each do |data|
      domain = data[:domain]
      level = data[:level_estimate]

      # Generate goal based on domain and level
      goal_title = generate_goal_title(domain, level)
      goal_description = generate_goal_description(domain, level)

      ChildGoal.create!(
        child_profile: @child_profile,
        profile_domain: domain,
        status: "suggested",
        short_title: goal_title,
        description: goal_description,
        priority_rank: priority_rank
      )

      priority_rank += 1
    end

    # Ensure we have at least 3 goals (fill with other domains if needed)
    if @child_profile.child_goals.suggested.count < 3
      remaining_domains = domain_scores.values
                                       .reject { |d| priority_domains.include?(d) }
                                       .select { |d| d[:answer_count] > 0 }
                                       .first(3 - @child_profile.child_goals.suggested.count)

      remaining_domains.each do |data|
        domain = data[:domain]
        level = data[:level_estimate]

        goal_title = generate_goal_title(domain, level)
        goal_description = generate_goal_description(domain, level)

        ChildGoal.create!(
          child_profile: @child_profile,
          profile_domain: domain,
          status: "suggested",
          short_title: goal_title,
          description: goal_description,
          priority_rank: priority_rank
        )

        priority_rank += 1
      end
    end
  end

  def generate_goal_title(domain, level)
    # Simple template-based goal generation
    # Later, replace with AI or more sophisticated templates
    case domain.key
    when "communication"
      level <= 1 ? "Responds when name is called" : "Uses words to express needs"
    when "social"
      level <= 1 ? "Engages in parallel play" : "Initiates social interactions"
    when "flexibility"
      level <= 1 ? "Handles routine changes with support" : "Adapts to unexpected changes"
    when "sensory"
      level <= 1 ? "Identifies sensory preferences" : "Uses sensory strategies for regulation"
    when "emotional_regulation"
      level <= 1 ? "Recognizes emotions" : "Uses coping strategies when upset"
    else
      "Develop skills in #{domain.label.downcase}"
    end
  end

  def generate_goal_description(domain, level)
    "Work on improving #{domain.label.downcase} skills through targeted activities and support."
  end

  def create_profile_summary(domain_scores)
    # Generate markdown summary
    content = build_profile_summary_markdown(domain_scores)

    AiDocument.create!(
      document_type: "profile_summary",
      child_profile: @child_profile,
      onboarding_session: @onboarding_session,
      created_by: @onboarding_session.user,
      content_markdown: content
    )
  end

  def build_profile_summary_markdown(domain_scores)
    strengths = []
    challenges = []

    domain_scores.each do |_key, data|
      next if data[:answer_count].zero?

      domain = data[:domain]
      level = data[:level_estimate]

      if level >= 3
        strengths << "#{domain.label}: Strong performance in this area"
      elsif level <= 1
        challenges << "#{domain.label}: Significant support needed"
      end
    end

    markdown = <<~MARKDOWN
      # Profile Summary for #{@child_profile.name}

      ## Strengths
      #{strengths.any? ? strengths.map { |s| "- #{s}" }.join("\n") : "- Strengths will be identified as we learn more about your child"}

      ## Challenges
      #{challenges.any? ? challenges.map { |c| "- #{c}" }.join("\n") : "- Challenges will be identified as we learn more about your child"}

      ## Suggested Goals
      #{@child_profile.child_goals.suggested.ordered_by_priority.map { |g| "- #{g.short_title}" }.join("\n")}

      ## Next Steps
      Review the suggested goals and activities to get started with home-based therapy support.
    MARKDOWN

    markdown
  end
end
