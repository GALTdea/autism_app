# Phase 1 MVP v0 - Detailed Specification

## Overview

**Goal**: A parent can sign up, answer smart questions, and walk away with a profile + a few spot-on insights that feel better than any intake form they've seen.

**Scope**: Parent-only, "Living Profile" Onboarding

## Phase Breakdown

Phase 1 is broken down into three manageable phases for incremental development and smaller, logical commits:

- **Phase 1a: Onboarding + Basic Profile Generation** - Parent completes questionnaire and sees basic text profile
- **Phase 1b: Profile Display & Visualization** - Beautiful, readable profile display with strengths, challenges, and goals
- **Phase 1c: Starter Activities** - Show 3-5 simple starter activities tied to goals (separate feature)

---

## Phase 1a: Onboarding + Basic Profile Generation

**Goal**: Parent can complete questionnaire and see a basic profile summary (text-based, minimal UI)

**Deliverable**: Parent completes onboarding → sees basic text profile summary with strengths, challenges, and suggested goals

### User Stories (Phase 1a)

1. I can create an account and sign in
2. I can add my child's basic information (name, age, diagnosis basics)
3. I can complete an onboarding questionnaire about my child
4. I can see questions organized by domain (communication, social, etc.)
5. I can answer questions with different response types (scale, multiple choice, text)
6. I can see follow-up questions based on my answers (adaptive questionnaire)
7. I can save my progress and resume later
8. I can complete the onboarding and see a generated profile (basic text summary)

### Features (Phase 1a)

#### 1. User & Child Setup

##### User Registration/Login
- Devise authentication
- Email/password login
- Password reset functionality

##### Add Child
- Form to add child profile:
  - Name (required)
  - Birth date (required)
  - Diagnosis summary (optional text field)
  - Main concerns (optional text field)
- Creates `ChildProfile` record
- Creates `ChildMembership` record with role: `parent`, `is_primary: true`

#### 2. Onboarding Questionnaire (Wizard)

##### Structure
- Multi-step wizard using Stimulus controller
- 4-6 main sections:
  1. **Communication**
     - Questions about verbal/non-verbal communication
     - Language level, comprehension, expression
  2. **Social & Play**
     - Social interaction, play skills, peer relationships
  3. **Flexibility & Behavior**
     - Routine changes, transitions, rigid behaviors
  4. **Sensory**
     - Sensory seeking/avoiding, sensitivities
  5. **Emotional Regulation**
     - Meltdowns, emotional expression, coping strategies
  6. **Parent Priorities**
     - "If we improved just ONE thing in 3 months, what would it be?"
     - Top 2-3 priorities selection

##### Question Types
- **Scale**: 0-4 or 0-5 scale (e.g., "Not yet", "Sometimes", "Often", "Always")
- **Multiple Choice**: Select one from options
- **Text**: Free-form response

##### Adaptive Logic
- Certain answers unlock follow-up questions
- Example: If parent indicates child has sensory sensitivities → show sensory detail questions
- Keep lightweight - max 2-3 levels of nesting

##### Wizard Features
- Progress indicator (step X of Y)
- Save progress automatically
- Can navigate back/forward
- Resume from last completed step
- Validation before proceeding

#### 3. Basic Profile Generation (Template-Based)

**Note**: This is a minimal implementation - basic text output. Full UI comes in Phase 1b.

##### Profile Summary (Text-Based)
Generated after onboarding completion, includes:

**Strengths Section**
- Lists child's identified strengths
- Based on positive answers and high scores
- Example: "Strong visual learning", "Enjoys structured activities"

**Challenges Section**
- Lists areas needing support
- Based on lower scores and parent concerns
- Example: "Difficulty with transitions", "Sensory sensitivities to loud sounds"

**Parent's Top Concerns**
- Highlights parent's stated priorities
- Shows what matters most to the family

**Hypotheses**
- Educated guesses about the child
- Example: "Seems more visual than verbal learner", "Gets stuck on routine changes"
- Based on answer patterns

##### Suggested Goals (3-5 goals)
- Written in parent-friendly language
- Tied to profile domains
- Status: `suggested` (parent can activate later)
- Examples:
  - "Responds when name is called"
  - "Can handle 'no' without big meltdown most of the time"
  - "Tolerates 5-minute transitions with visual support"
- Stored in database, displayed as simple list in Phase 1a

### Implementation Plan (Phase 1a)

**Commit 1: Database & Models Foundation**
- All migrations (child_profiles, questions, answers, onboarding_sessions, profile_domains, child_domain_profiles, child_goals, ai_documents)
- All models with associations and validations
- Seed data (profile_domains, initial questions)

**Commit 2: Onboarding Backend**
- OnboardingService (start, save answer, complete)
- Answer persistence logic
- Basic adaptive question logic

**Commit 3: Onboarding Wizard UI**
- Multi-step wizard with Stimulus controller
- Question forms (scale, multi-choice, text)
- Progress tracking
- Save/resume functionality

**Commit 4: Basic Profile Generation**
- ProfileGenerationService (template-based, minimal)
- Generates basic profile summary (text only, simple display)
- Creates domain profiles and suggested goals in database
- Shows simple text summary after completion

---

## Phase 1b: Profile Display & Visualization

**Goal**: Beautiful, readable profile display with strengths, challenges, and goals

**Deliverable**: Parent can view a well-formatted profile with visual elements, domain scores, and clearly displayed goals

### User Stories (Phase 1b)

9. I can see my child's strengths and challenges (enhanced UI)
10. I can see suggested therapy goals in parent-friendly language (enhanced UI)

### Features (Phase 1b)

#### 1. Profile Display UI

##### Profile View Page
- Well-formatted, readable summary
- Visual indicators for domain scores (simple bars or badges)
- Strengths section with clear formatting
- Challenges section with clear formatting
- Parent's top concerns highlighted
- Hypotheses displayed clearly
- Print-friendly styling

#### 2. Goals Display

##### Goals List View
- Goals displayed as cards or list items
- Goal status indicators (suggested, active, paused, archived)
- Parent-friendly language formatting
- Organized by domain or priority
- Clear visual hierarchy

### Implementation Plan (Phase 1b)

**Commit 1: Profile Display UI**
- Profile view page layout
- Strengths section styling
- Challenges section styling
- Domain scores visualization (bars/badges)
- Responsive design

**Commit 2: Goals Display**
- Goals list/card view
- Goal status indicators
- Domain organization
- Visual polish

---

## Phase 1c: Starter Activities

**Goal**: Show 3-5 simple starter activities tied to goals

**Deliverable**: Parent sees suggested activities they can try at home

### User Stories (Phase 1c)

11. I can see 3-5 simple starter activities tied to those goals

### Features (Phase 1c)

#### 1. Activity Models & Data

##### Activity Structure
- ActivityTemplate model (or simple data structure for Phase 1)
- Seed 3-5 basic activities
- Link activities to goals/domains
- Activity attributes:
  - Title
  - Description/instructions
  - Duration (5-10 minutes)
  - Materials needed (home items)
  - Target domain
  - Related goals

#### 2. Activity Display

##### Activities Section
- Activities section on profile page
- Activity cards with "recipe card" UI
- Clear instructions
- Materials list
- Duration indicator
- Link to related goals

### Implementation Plan (Phase 1c)

**Commit 1: Activity Models & Data**
- ActivityTemplate model (or data structure)
- Seed 3-5 basic activities
- Link activities to goals/domains

**Commit 2: Activity Display**
- Activities section on profile page
- Activity cards with instructions
- Simple "recipe card" UI
- Visual polish

## Database Schema

### Core Tables (All Phases)

**Phase 1a Required:**
- `users` (already exists, extend if needed)
- `child_profiles`
- `child_memberships`
- `onboarding_sessions`
- `profile_domains` (seed data)
- `questions` (seed data)
- `question_options` (seed data)
- `answers`
- `child_domain_profiles`
- `child_goals`
- `ai_documents`

**Phase 1c Required:**
- `activity_templates` (or simple data structure)

### Relationships

**Core Relationships:**
- User has_many ChildMemberships
- ChildProfile has_many ChildMemberships
- ChildProfile has_many OnboardingSessions
- OnboardingSession has_many Answers
- Question has_many QuestionOptions
- Question has_many Answers
- ChildProfile has_many ChildDomainProfiles
- ProfileDomain has_many ChildDomainProfiles
- ChildProfile has_many ChildGoals
- ProfileDomain has_many ChildGoals
- ChildProfile has_many AiDocuments

**Phase 1c Relationships:**
- ActivityTemplate belongs_to ProfileDomain (optional)
- ActivityTemplate has_many ChildGoals (or many-to-many)

## Implementation Details

### Phase 1a: Template-Based Profile Generation

#### Template Structure (YAML)
```yaml
profiles:
  - name: "visual_learner_high_sensory"
    conditions:
      communication_visual_score: "high"
      sensory_seeking: true
    strengths:
      - "Strong visual processing"
      - "Detail-oriented"
    challenges:
      - "Sensory overload in busy environments"
      - "May need visual supports for transitions"
    suggested_goals:
      - domain: "communication"
        title: "Uses visual schedule for daily routines"
      - domain: "sensory"
        title: "Takes sensory breaks when overwhelmed"
```

#### Matching Algorithm
1. Score answers by domain
2. Match against template conditions
3. Select best-matching template(s)
4. Generate profile from template
5. Customize with child-specific details from answers

### Service Objects

#### OnboardingService (Phase 1a)
```ruby
class OnboardingService
  def self.start_session(user, child_profile)
    # Create onboarding session
  end

  def self.save_answer(session, question_id, answer_data)
    # Save or update answer
    # Check for dependent questions
  end

  def self.complete_session(session)
    # Mark session as completed
    # Trigger profile generation
  end
end
```

#### ProfileGenerationService (Phase 1a)
```ruby
class ProfileGenerationService
  def self.generate_profile(child_profile, onboarding_session)
    # Load templates
    # Score answers
    # Match template
    # Create domain profiles
    # Generate goals
    # Create AI document (basic text summary)
  end
end
```

### Phase 1c: Activity System

#### ActivityTemplate Model (Simple for Phase 1)
```ruby
class ActivityTemplate
  # Attributes:
  # - title
  # - description
  # - instructions (text)
  # - duration_minutes
  # - materials (text or array)
  # - target_domain_id
  # - related_goal_ids (array or join table)
end
```

## UI/UX Requirements

### Design Principles (All Phases)
- **Respectful**: Person-first language, positive framing
- **Clear**: Simple, uncluttered interface
- **Supportive**: Acknowledge this can be emotional for parents
- **Accessible**: Keyboard navigation, screen reader support

### Phase 1a: Onboarding Wizard UI
- Clean, step-by-step interface
- Progress bar at top
- One question per screen (or small group)
- Clear "Next" and "Back" buttons
- "Save and continue later" option
- Mobile-responsive
- Basic profile summary display (text-based, minimal styling)

### Phase 1b: Profile Display UI
- Well-formatted, readable summary
- Visual indicators for domain scores (simple bars or badges)
- Goals displayed clearly with cards/list view
- Print-friendly styling
- Responsive design

### Phase 1c: Activity Display UI
- Activities displayed as "recipe cards"
- Clear instructions
- Materials list
- Duration indicator
- Link to related goals
- Simple, home-friendly design

## Success Metrics

### Phase 1a Success Metrics
- Parents complete onboarding in < 15 minutes
- Parents can save and resume onboarding
- Profile generation completes in < 5 seconds
- Basic profile summary is readable and accurate
- Low abandonment rate during onboarding

### Phase 1b Success Metrics
- Parents say "This description sounds like my kid"
- Profile display is visually appealing and easy to read
- Goals are clearly presented and understandable
- Parents can easily identify strengths and challenges

### Phase 1c Success Metrics
- Parents find suggested activities usable
- Activities are clear and actionable
- Activities are appropriately matched to goals

### Technical Metrics (All Phases)
- Onboarding can be resumed if interrupted
- All data properly saved and associated
- Responsive design works on mobile devices
- Page load times < 2 seconds

## Future Enhancements (Post-Phase 1)

- AI-powered profile generation (replace templates)
- Activity system with logging
- Behavior tracking
- Multi-user collaboration
- Adaptive coaching
- Weekly summaries
- Therapist integration

## Testing Requirements

### Phase 1a Testing
**Unit Tests:**
- Model validations and associations
- OnboardingService logic
- Answer persistence
- Adaptive question logic

**Integration Tests:**
- Complete onboarding flow
- Profile generation flow
- User authentication flow
- Save/resume functionality

**System Tests:**
- Full onboarding journey: sign up → add child → complete onboarding → see basic profile

### Phase 1b Testing
**Unit Tests:**
- ProfileGenerationService (if enhanced)
- Profile display helpers

**Integration Tests:**
- Profile display with all data
- Goals display

**System Tests:**
- View profile after onboarding
- Navigate to goals section

### Phase 1c Testing
**Unit Tests:**
- ActivityTemplate model
- Activity-goal associations

**Integration Tests:**
- Activity display on profile page
- Activity-goal linking

**System Tests:**
- View activities after profile generation
- Navigate from goals to activities

