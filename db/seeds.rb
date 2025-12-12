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

puts "\nSeeding Activity Templates..."

def create_activity_template(domain, data)
  activity = ActivityTemplate.find_or_create_by!(title: data[:title]) do |a|
    a.primary_target = domain
    a.duration_minutes = data[:duration_minutes]
    a.materials = data[:materials]
    a.parent_script = data[:parent_script]
    a.variation = data[:variation]
    a.secondary_target_ids = data[:secondary_target_ids] || []
    a.target_tags = data[:target_tags] || []
    a.age_bands = data[:age_bands] || ['3-5', '6-8', '9-11']
    a.language_level_required = data[:language_level_required] || 'single_words'
    a.motor_demands = data[:motor_demands] || 'low'
    a.difficulty_level = data[:difficulty_level] || 2
    a.energy_level = data[:energy_level] || 'neutral'
    a.contexts = data[:contexts] || ['home']
    a.materials_category = data[:materials_category] || 'household'
    a.scripts_by_level = data[:scripts_by_level] || {}
    a.sensory_fit = data[:sensory_fit] || {}
    a.noise_level = data[:noise_level] || {}
    a.movement_level = data[:movement_level] || {}
    a.variations = data[:variations] || []
    a.prerequisites = data[:prerequisites] || {}
    a.sensory_profile_tags = data[:sensory_profile_tags] || []
    a.supports_concerns = data[:supports_concerns] || []
    a.active = data.fetch(:active, true)
    a.position = data[:position] || 0
  end
  activity
end

# Communication Domain Activities
comm_activities = [
  {
    title: "Name Game",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "Let's practice saying your name! When I call your name, you can say 'Here!' or just look at me.",
    variation: "Try using a favorite toy - 'Where's [Toy Name]?' and have them point or say the name.",
    target_tags: ['name_response', 'attention'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'pre_verbal',
    difficulty_level: 1,
    contexts: ['home', 'car'],
    supports_concerns: ['name_response', 'attention']
  },
  {
    title: "Picture Choice Board",
    duration_minutes: 10,
    materials: "Pictures of favorite items (toys, snacks, activities), cardboard or paper, tape",
    parent_script: "Let's make choices! Show me which picture you want. You can point or say the word.",
    variation: "Start with just 2 choices, then add more as they get comfortable.",
    target_tags: ['choice_making', 'communication'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'pre_verbal',
    difficulty_level: 2,
    contexts: ['home'],
    materials_category: 'craft',
    supports_concerns: ['choice_making', 'communication']
  },
  {
    title: "What's in the Bag?",
    duration_minutes: 10,
    materials: "Small bag or box, 3-5 familiar objects (cup, ball, book, etc.)",
    parent_script: "Let's see what's in here! Can you tell me what this is? What do we do with it?",
    variation: "Use mystery box - child reaches in and describes what they feel before seeing it.",
    target_tags: ['vocabulary', 'describing'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    contexts: ['home'],
    supports_concerns: ['vocabulary', 'describing']
  },
  {
    title: "I Spy",
    duration_minutes: 5,
    materials: "None needed - use items around you",
    parent_script: "I spy something blue! Can you find it? Now you spy something!",
    variation: "Use colors, shapes, or first letter sounds depending on child's level.",
    target_tags: ['vocabulary', 'turn_taking'],
    age_bands: ['6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 2,
    contexts: ['home', 'car'],
    supports_concerns: ['vocabulary', 'turn_taking']
  },
  {
    title: "Story Time with Questions",
    duration_minutes: 10,
    materials: "Favorite book",
    parent_script: "Let's read together! What do you think will happen next? Who is this?",
    variation: "Use wordless picture books and have child tell the story.",
    target_tags: ['wh_questions', 'comprehension'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 3,
    contexts: ['home', 'bedtime'],
    materials_category: 'household',
    supports_concerns: ['wh_questions', 'comprehension']
  }
]

# Social Domain Activities
social_activities = [
  {
    title: "Parallel Play",
    duration_minutes: 10,
    materials: "Two sets of similar toys (blocks, cars, dolls)",
    parent_script: "Let's play side by side! You play with your blocks, I'll play with mine. Look what I'm making!",
    variation: "Gradually move closer together, then try sharing one toy.",
    target_tags: ['parallel_play', 'social_proximity'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'pre_verbal',
    difficulty_level: 1,
    contexts: ['home'],
    supports_concerns: ['parallel_play', 'social_proximity']
  },
  {
    title: "Turn Taking with Toys",
    duration_minutes: 5,
    materials: "One special toy (ball, car, puzzle piece)",
    parent_script: "My turn! Now your turn! Can you wait while I have a turn?",
    variation: "Use a timer - when it beeps, it's the other person's turn.",
    target_tags: ['turn_taking', 'waiting'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    contexts: ['home'],
    supports_concerns: ['turn_taking', 'waiting']
  },
  {
    title: "Mirror Game",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "Copy what I do! Make the same face, do the same action. Now you lead!",
    variation: "Use emotions - make a happy face, sad face, surprised face.",
    target_tags: ['imitation', 'social_attention'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'pre_verbal',
    difficulty_level: 1,
    contexts: ['home'],
    supports_concerns: ['imitation', 'social_attention']
  },
  {
    title: "Greeting Practice",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "When someone says 'Hi!', you can say 'Hi!' back and wave. Let's practice!",
    variation: "Practice with family photos or stuffed animals first.",
    target_tags: ['greetings', 'social_interaction'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    contexts: ['home'],
    supports_concerns: ['greetings', 'social_interaction']
  }
]

# Flexibility Domain Activities
flexibility_activities = [
  {
    title: "Visual Schedule",
    duration_minutes: 10,
    materials: "Paper, markers, pictures or drawings of daily activities",
    parent_script: "Let's make a picture schedule! First we do this, then this. Sometimes things change, and that's okay!",
    variation: "Use actual photos of your child doing activities for more personal connection.",
    target_tags: ['transitions', 'routine', 'visual_support'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'pre_verbal',
    difficulty_level: 2,
    contexts: ['home'],
    materials_category: 'craft',
    supports_concerns: ['transitions', 'routine_changes']
  },
  {
    title: "Change the Plan",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "We were going to do X, but now let's do Y instead! That's okay, we can be flexible.",
    variation: "Start with very small changes (different cup, different chair) and build up.",
    target_tags: ['flexibility', 'routine_changes'],
    age_bands: ['6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 3,
    contexts: ['home'],
    supports_concerns: ['routine_changes', 'flexibility']
  },
  {
    title: "First-Then Board",
    duration_minutes: 5,
    materials: "Cardboard, pictures, velcro or tape",
    parent_script: "First we do this (point), then we do this (point). Let's check it off when we're done!",
    variation: "Use a simple whiteboard and draw quick pictures.",
    target_tags: ['transitions', 'following_directions'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'pre_verbal',
    difficulty_level: 2,
    contexts: ['home'],
    materials_category: 'craft',
    supports_concerns: ['transitions', 'following_directions']
  },
  {
    title: "Unexpected Change Practice",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "Oops! Something changed. That's okay, we can handle it. Let's take a deep breath.",
    variation: "Practice with very small, positive changes first (different snack, different route).",
    target_tags: ['flexibility', 'emotional_regulation'],
    age_bands: ['6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 4,
    contexts: ['home'],
    supports_concerns: ['routine_changes', 'flexibility']
  }
]

# Sensory Domain Activities
sensory_activities = [
  {
    title: "Deep Pressure Squeeze",
    duration_minutes: 5,
    materials: "Pillows, weighted blanket, or your hands",
    parent_script: "Let's give you a big, gentle squeeze! Does that feel good? Tell me when to stop.",
    variation: "Use a compression shirt or wrap child in a blanket like a burrito.",
    target_tags: ['deep_pressure', 'calming'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'pre_verbal',
    difficulty_level: 1,
    energy_level: 'calming',
    contexts: ['home', 'bedtime'],
    sensory_profile_tags: ['likes_deep_pressure'],
    supports_concerns: ['sensory_regulation', 'calming']
  },
  {
    title: "Sensory Bin",
    duration_minutes: 10,
    materials: "Bin or container, rice/beans/sand, small toys or objects",
    parent_script: "Let's dig and find treasures! How does this feel? Is it smooth or rough?",
    variation: "Use different textures - water beads, shaving cream, dry pasta.",
    target_tags: ['sensory_exploration', 'tactile'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    contexts: ['home'],
    materials_category: 'household',
    sensory_profile_tags: ['seeks_tactile'],
    supports_concerns: ['sensory_exploration']
  },
  {
    title: "Movement Break",
    duration_minutes: 5,
    materials: "None needed",
    parent_script: "Let's move our bodies! Jump, spin, stretch. How does that feel?",
    variation: "Follow movement cards or YouTube videos for guided movement.",
    target_tags: ['movement', 'proprioception'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'pre_verbal',
    difficulty_level: 1,
    energy_level: 'energizing',
    motor_demands: 'medium',
    contexts: ['home'],
    sensory_profile_tags: ['seeks_movement'],
    supports_concerns: ['sensory_regulation']
  },
  {
    title: "Quiet Time Corner",
    duration_minutes: 10,
    materials: "Pillows, blanket, soft lighting, maybe headphones",
    parent_script: "This is your quiet space. When things feel too loud or busy, you can come here.",
    variation: "Add favorite calming items - stuffed animal, favorite book, fidget toy.",
    target_tags: ['calming', 'self_regulation'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'pre_verbal',
    difficulty_level: 2,
    energy_level: 'calming',
    contexts: ['home'],
    sensory_profile_tags: ['avoids_loud_noise', 'needs_quiet'],
    supports_concerns: ['sensory_overload', 'calming']
  },
  {
    title: "Texture Walk",
    duration_minutes: 5,
    materials: "Different textures on floor (towel, bubble wrap, carpet square, smooth tile)",
    parent_script: "Walk on this! How does it feel? Soft? Bumpy? Let's try the next one!",
    variation: "Blindfold and guess the texture, or match textures with hands and feet.",
    target_tags: ['tactile', 'sensory_exploration'],
    age_bands: ['3-5', '6-8'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    motor_demands: 'low',
    contexts: ['home'],
    sensory_profile_tags: ['seeks_tactile'],
    supports_concerns: ['sensory_exploration']
  }
]

# Emotional Regulation Domain Activities
emotion_activities = [
  {
    title: "Emotion Faces",
    duration_minutes: 5,
    materials: "Mirror, emotion cards or pictures",
    parent_script: "Let's make faces! Show me happy, sad, angry, surprised. How do you feel right now?",
    variation: "Use emotion cards to match feelings, or draw faces together.",
    target_tags: ['emotion_recognition', 'emotion_expression'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'single_words',
    difficulty_level: 2,
    contexts: ['home'],
    supports_concerns: ['emotion_recognition']
  },
  {
    title: "Calm Down Box",
    duration_minutes: 10,
    materials: "Box, calming items (fidget toy, stress ball, favorite picture, calming music)",
    parent_script: "When you feel upset, you can use things from this box to help you feel better.",
    variation: "Create the box together, letting child choose what goes inside.",
    target_tags: ['self_regulation', 'coping_strategies'],
    age_bands: ['6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 3,
    contexts: ['home'],
    materials_category: 'household',
    supports_concerns: ['emotional_regulation', 'coping_strategies']
  },
  {
    title: "Breathing Buddy",
    duration_minutes: 5,
    materials: "Stuffed animal or small toy",
    parent_script: "Watch your breathing buddy go up and down as you breathe. In... out... slow and calm.",
    variation: "Use bubbles - blow slowly and watch them float. Or use a pinwheel.",
    target_tags: ['breathing', 'calming'],
    age_bands: ['3-5', '6-8', '9-11'],
    language_level_required: 'pre_verbal',
    difficulty_level: 2,
    energy_level: 'calming',
    contexts: ['home', 'bedtime'],
    supports_concerns: ['calming', 'self_regulation']
  },
  {
    title: "Feelings Check-In",
    duration_minutes: 5,
    materials: "Feelings chart or emotion cards",
    parent_script: "How are you feeling right now? Point to the face that matches, or tell me.",
    variation: "Use a feelings thermometer (1-5 scale) or color-coded feelings.",
    target_tags: ['emotion_identification', 'self_awareness'],
    age_bands: ['6-8', '9-11'],
    language_level_required: 'short_phrases',
    difficulty_level: 2,
    contexts: ['home'],
    supports_concerns: ['emotion_identification']
  }
]

# Create activities
position = 1
[comm_activities, social_activities, flexibility_activities, sensory_activities, emotion_activities].each_with_index do |activities, domain_index|
  domain_key = ['communication', 'social', 'flexibility', 'sensory', 'emotional_regulation'][domain_index]
  domain = profile_domains[domain_key]
  
  activities.each do |activity_data|
    activity_data[:position] = position
    create_activity_template(domain, activity_data)
    puts "  ✓ #{activity_data[:title]} (#{domain.label})"
    position += 1
  end
end

puts "\n✓ Seed data complete!"
puts "  - #{ProfileDomain.count} profile domains"
puts "  - #{Question.count} questions"
puts "  - #{QuestionOption.count} question options"
puts "  - #{ActivityTemplate.count} activity templates"
