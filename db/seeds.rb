# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding Profile Domains..."

# Profile Domains
domains = [
  { key: 'communication', label: 'Communication', description: 'Verbal and non-verbal communication skills' },
  { key: 'social', label: 'Social & Play', description: 'Social interaction, play skills, and peer relationships' },
  { key: 'flexibility', label: 'Flexibility & Behavior', description: 'Adaptability, routine changes, and behavioral flexibility' },
  { key: 'sensory', label: 'Sensory Processing', description: 'Sensory seeking, avoiding, and regulation' },
  { key: 'emotional_regulation', label: 'Emotional Regulation', description: 'Emotional expression, coping strategies, and self-regulation' }
]

profile_domains = {}
domains.each do |domain_data|
  domain = ProfileDomain.find_or_create_by!(key: domain_data[:key]) do |d|
    d.label = domain_data[:label]
    d.description = domain_data[:description]
  end
  profile_domains[domain_data[:key]] = domain
  puts "  ✓ #{domain.label}"
end

puts "\nSeeding Questions..."

# Communication Domain Questions
comm_domain = profile_domains['communication']
comm_questions = [
  {
    code: 'COMM_1',
    text: 'How does your child communicate their needs and wants?',
    response_type: 'multi_choice',
    position: 1,
    options: [
      { label: 'Uses full sentences', value: 4 },
      { label: 'Uses phrases or short sentences', value: 3 },
      { label: 'Uses single words', value: 2 },
      { label: 'Uses gestures or pointing', value: 1 },
      { label: 'Limited communication', value: 0 }
    ]
  },
  {
    code: 'COMM_2',
    text: 'Does your child respond when you call their name?',
    response_type: 'scale',
    position: 2,
    options: [
      { label: 'Always', value: 4 },
      { label: 'Often', value: 3 },
      { label: 'Sometimes', value: 2 },
      { label: 'Rarely', value: 1 },
      { label: 'Not yet', value: 0 }
    ]
  },
  {
    code: 'COMM_3',
    text: 'How well does your child understand spoken instructions?',
    response_type: 'scale',
    position: 3,
    options: [
      { label: 'Understands complex instructions', value: 4 },
      { label: 'Understands simple multi-step instructions', value: 3 },
      { label: 'Understands simple one-step instructions', value: 2 },
      { label: 'Understands with visual support', value: 1 },
      { label: 'Limited understanding', value: 0 }
    ]
  },
  {
    code: 'COMM_4',
    text: 'Does your child use visual supports (pictures, schedules) to communicate?',
    response_type: 'scale',
    position: 4,
    options: [
      { label: 'Uses independently', value: 4 },
      { label: 'Uses with prompting', value: 3 },
      { label: 'Shows interest but needs support', value: 2 },
      { label: 'Not yet, but might benefit', value: 1 },
      { label: 'Not applicable', value: 0 }
    ]
  }
]

# Social Domain Questions
social_domain = profile_domains['social']
social_questions = [
  {
    code: 'SOCIAL_1',
    text: 'How does your child interact with peers?',
    response_type: 'multi_choice',
    position: 1,
    options: [
      { label: 'Initiates and maintains interactions', value: 4 },
      { label: 'Responds to peer initiations', value: 3 },
      { label: 'Plays near peers (parallel play)', value: 2 },
      { label: 'Plays alone, shows some interest', value: 1 },
      { label: 'Prefers to play alone', value: 0 }
    ]
  },
  {
    code: 'SOCIAL_2',
    text: 'Does your child make eye contact during interactions?',
    response_type: 'scale',
    position: 2,
    options: [
      { label: 'Always', value: 4 },
      { label: 'Often', value: 3 },
      { label: 'Sometimes', value: 2 },
      { label: 'Rarely', value: 1 },
      { label: 'Not yet', value: 0 }
    ]
  },
  {
    code: 'SOCIAL_3',
    text: 'How does your child handle sharing toys or taking turns?',
    response_type: 'scale',
    position: 3,
    options: [
      { label: 'Shares and takes turns easily', value: 4 },
      { label: 'Shares with reminders', value: 3 },
      { label: 'Shares sometimes, needs support', value: 2 },
      { label: 'Has difficulty sharing', value: 1 },
      { label: 'Significant difficulty', value: 0 }
    ]
  }
]

# Flexibility Domain Questions
flex_domain = profile_domains['flexibility']
flex_questions = [
  {
    code: 'FLEX_1',
    text: 'How does your child handle changes in routine?',
    response_type: 'scale',
    position: 1,
    options: [
      { label: 'Adapts easily to changes', value: 4 },
      { label: 'Adapts with preparation', value: 3 },
      { label: 'Has some difficulty, needs support', value: 2 },
      { label: 'Significant difficulty with changes', value: 1 },
      { label: 'Very rigid, changes cause distress', value: 0 }
    ]
  },
  {
    code: 'FLEX_2',
    text: 'How does your child handle transitions (e.g., leaving home, ending activities)?',
    response_type: 'scale',
    position: 2,
    options: [
      { label: 'Transitions smoothly', value: 4 },
      { label: 'Transitions with warnings', value: 3 },
      { label: 'Needs visual/timer support', value: 2 },
      { label: 'Has difficulty transitioning', value: 1 },
      { label: 'Transitions cause meltdowns', value: 0 }
    ]
  },
  {
    code: 'FLEX_3',
    text: 'Can your child handle being told "no" or not getting their way?',
    response_type: 'scale',
    position: 3,
    options: [
      { label: 'Handles it well', value: 4 },
      { label: 'Handles it with some support', value: 3 },
      { label: 'Has difficulty, needs strategies', value: 2 },
      { label: 'Significant difficulty', value: 1 },
      { label: 'Often leads to meltdown', value: 0 }
    ]
  }
]

# Sensory Domain Questions
sensory_domain = profile_domains['sensory']
sensory_questions = [
  {
    code: 'SENSORY_1',
    text: 'How does your child respond to loud sounds?',
    response_type: 'scale',
    position: 1,
    options: [
      { label: 'No issues with loud sounds', value: 4 },
      { label: 'Occasionally bothered', value: 3 },
      { label: 'Often covers ears or avoids', value: 2 },
      { label: 'Very sensitive, avoids loud places', value: 1 },
      { label: 'Extreme sensitivity, causes distress', value: 0 }
    ]
  },
  {
    code: 'SENSORY_2',
    text: 'Does your child seek out sensory input (spinning, jumping, touching textures)?',
    response_type: 'scale',
    position: 2,
    options: [
      { label: 'No unusual seeking', value: 4 },
      { label: 'Occasional seeking', value: 3 },
      { label: 'Regular seeking behaviors', value: 2 },
      { label: 'Frequent seeking, needs regulation', value: 1 },
      { label: 'Constant seeking, interferes with activities', value: 0 }
    ]
  },
  {
    code: 'SENSORY_3',
    text: 'How does your child handle different textures (food, clothing, surfaces)?',
    response_type: 'scale',
    position: 3,
    options: [
      { label: 'No issues with textures', value: 4 },
      { label: 'Some preferences but flexible', value: 3 },
      { label: 'Strong preferences, some avoidance', value: 2 },
      { label: 'Many textures cause discomfort', value: 1 },
      { label: 'Extreme sensitivity to textures', value: 0 }
    ]
  }
]

# Emotional Regulation Domain Questions
emotion_domain = profile_domains['emotional_regulation']
emotion_questions = [
  {
    code: 'EMOTION_1',
    text: 'How often does your child have meltdowns or emotional outbursts?',
    response_type: 'scale',
    position: 1,
    options: [
      { label: 'Rarely or never', value: 4 },
      { label: 'Occasionally (once a week or less)', value: 3 },
      { label: 'A few times a week', value: 2 },
      { label: 'Daily', value: 1 },
      { label: 'Multiple times daily', value: 0 }
    ]
  },
  {
    code: 'EMOTION_2',
    text: 'Can your child identify and express their emotions?',
    response_type: 'scale',
    position: 2,
    options: [
      { label: 'Expresses emotions clearly', value: 4 },
      { label: 'Expresses with support', value: 3 },
      { label: 'Shows emotions but struggles to express', value: 2 },
      { label: 'Limited emotional expression', value: 1 },
      { label: 'Difficulty identifying emotions', value: 0 }
    ]
  },
  {
    code: 'EMOTION_3',
    text: 'Does your child use coping strategies when upset (breathing, taking a break)?',
    response_type: 'scale',
    position: 3,
    options: [
      { label: 'Uses strategies independently', value: 4 },
      { label: 'Uses strategies with reminders', value: 3 },
      { label: 'Learning strategies, needs support', value: 2 },
      { label: 'Struggles to use strategies', value: 1 },
      { label: 'No coping strategies yet', value: 0 }
    ]
  }
]

# Parent Priorities (text-based question)
priority_question = {
  code: 'PRIORITY_1',
  text: 'If we could improve just ONE thing in the next 3 months, what would matter most to you?',
  response_type: 'text',
  position: 1,
  options: []
}

# Helper method to create questions
def create_question(domain, question_data)
  question = Question.find_or_create_by!(code: question_data[:code]) do |q|
    q.text = question_data[:text]
    q.response_type = question_data[:response_type]
    q.position = question_data[:position]
    q.profile_domain = domain
    q.domain = domain.key
  end

  # Create question options if provided
  if question_data[:options].present?
    question_data[:options].each_with_index do |option_data, index|
      QuestionOption.find_or_create_by!(
        question: question,
        value: option_data[:value]
      ) do |opt|
        opt.label = option_data[:label]
        opt.position = index
      end
    end
  end

  question
end

# Create all questions
[comm_questions, social_questions, flex_questions, sensory_questions, emotion_questions].each_with_index do |questions, index|
  domain_keys = ['communication', 'social', 'flexibility', 'sensory', 'emotional_regulation']
  domain = profile_domains[domain_keys[index]]

  questions.each do |q_data|
    create_question(domain, q_data)
    puts "  ✓ #{q_data[:code]}: #{q_data[:text][0..60]}..."
  end
end

# Create priority question (no specific domain, but we'll use a general one)
priority_domain = profile_domains['communication'] # Using communication as placeholder
create_question(priority_domain, priority_question)
puts "  ✓ PRIORITY_1: Parent priorities question"

puts "\n✓ Seed data complete!"
puts "  - #{ProfileDomain.count} profile domains"
puts "  - #{Question.count} questions"
puts "  - #{QuestionOption.count} question options"
