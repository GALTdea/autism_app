# Phase 2 – Activities, Recommendation Engine v1, and Tiny Logging

## Overview

**Goal**: Introduce simple activity cards parents can use at home, generate daily recommendations, add fast logging, and provide minimal weekly feedback to establish a basic daily-habit loop.

**Scope**: Parent-only, activity-based home therapy with rule-based recommendations

## Phase Breakdown

Phase 2 is broken down into four manageable sub-phases for incremental development and testing:

- **Phase 2a: Activity Foundation & Profile Extensions** - Activity templates, profile data extraction, basic activity display
- **Phase 2b: Recommendation Engine & Daily Recommendations** - Rule-based recommendation algorithm, daily caching, parent context preferences
- **Phase 2c: Activity Logging** - Fast logging interface, activity completion tracking
- **Phase 2d: Weekly Feedback** - Minimal weekly summary with insights

---

## Key Architectural Decisions

1. **Activity Targets**: Use existing `ProfileDomain` keys as primary mapping + secondary `target_tags` JSONB layer for specificity (e.g., denied_access, transitions_off_screen, turn_taking, wh_questions)

2. **Database Design**: Key filter fields (domain, duration, difficulty_level, energy_level, contexts) as real columns. Long-tail metadata (scripts_by_level, sensory_fit, variations) in JSONB.

3. **Language Profile**: Store `expressive_level`, `receptive_level`, `supports` in `ChildDomainProfile` for communication domain. Activity templates include `scripts_by_level` JSONB.

4. **Sensory Profile**: Store `seeking_level`, `avoiding_level`, `sensitivity_tags` in `ChildDomainProfile` for sensory domain.

5. **Parent Context Preferences**: Parent-set (onboarding + settings), stored in `child_profile.preferred_contexts` JSONB.

6. **Activity-Goal Matching**: Match by `profile_domain_id` + `target_tags` overlap. Goals have `target_tags` JSONB array.

7. **Recommendation Caching**: `DailyRecommendation` model with background job (6 AM daily), on-demand fallback.

8. **Weekly Feedback**: Generate on-demand, cache in `AiDocument`.

9. **Activity Template Management**: Admin-only CRUD in Avo for Phase 2.

---

## Phase 2a: Activity Foundation & Profile Extensions

**Goal**: Set up activity templates, extend child profiles with language/sensory data, and display basic activity cards.

**Deliverable**: Parent can view activity cards with all visible fields. Profile generation extracts language and sensory profiles.

### User Stories (Phase 2a)

1. I can see activity cards with title, target, time, materials, parent script, and variation
2. My child's language level is captured during onboarding (expressive and receptive)
3. My child's sensory profile is captured during onboarding (seeking, avoiding, sensitivity tags)
4. I can set my preferred contexts for activities (onboarding + settings)

### Features (Phase 2a)

#### 1. Activity Templates

**Visible Fields** (shown to parents):
- Title
- Target (ProfileDomain: communication, flexibility, sensory, social, daily living, self-regulation)
- Time (5 or 10 minutes)
- Materials (list of home items)
- Parent Script ("You can say…")
- One Simple Variation

**Metadata Fields** (for recommendation engine):
- Primary target (ProfileDomain)
- Secondary targets (array of ProfileDomain IDs)
- Target tags (JSONB array for specificity)
- Age bands (3-5, 6-8, 9-11)
- Duration (5 or 10 minutes)
- Difficulty level (1-5)
- Energy level (calming, neutral, energizing)
- Language level required (pre-verbal, single_words, short_phrases, sentences)
- Motor demands (low, medium, high)
- Contexts (array: home, car, park, mealtime, bedtime, etc.)
- Materials category (household, toys, craft, none)
- Scripts by level (JSONB: scripts for different language levels)
- Sensory fit, noise level, movement level (JSONB)
- Variations, prerequisites (JSONB)
- Sensory profile tags, supports concerns (JSONB arrays)

**Seed Data**: 20-30 initial activity templates

#### 2. Profile Data Extensions

**ChildDomainProfile Extensions**:
- For communication domain: `expressive_level`, `receptive_level`, `supports` (JSONB array)
- For sensory domain: `seeking_level`, `avoiding_level`, `sensitivity_tags` (JSONB array)

**ChildProfile Extensions**:
- `preferred_contexts` (JSONB array): preferred times, duration preferences, environment constraints, materials tolerance

**ChildGoal Extensions**:
- `target_tags` (JSONB array): specificity tags for matching

#### 3. Profile Generation Updates

- Extract language profile from communication domain answers
- Extract sensory profile from sensory domain answers
- Store structured data in ChildDomainProfile

#### 4. Activity Display

- Activity show page with all visible fields
- Basic activity list view (for admin/testing)

### Implementation Notes (Phase 2a)

- Create `activity_templates` table with proper column/JSONB split
- Extend `child_domain_profiles`, `child_profiles`, `child_goals` tables
- Update `ProfileGenerationService` to extract and store language/sensory profiles
- Add parent context preferences capture in onboarding
- Add parent context preferences settings page
- Seed 20-30 activity templates

---

## Phase 2b: Recommendation Engine & Daily Recommendations

**Goal**: Implement rule-based recommendation algorithm that generates 3 daily activities per child.

**Deliverable**: Parent sees 3 recommended activities each day, personalized to their child's profile and goals.

### User Stories (Phase 2b)

5. I see 3 recommended activities when I open the app
6. Recommendations match my child's age, goals, and preferences
7. Recommendations avoid activities my child didn't enjoy recently
8. Recommendations include variety (favorites, goal-focused, novelty)

### Features (Phase 2b)

#### 1. Recommendation Algorithm (Rule-Based)

**Step 1 — Filter Activities**:
- Match age band (child's age within activity's age_bands)
- Match contexts (activity contexts overlap with parent's preferred_contexts)
- Fit sensory preferences (activity sensory tags align with child's sensory profile)
- Exclude sensory "no-go" tags (if child avoids loud noise, exclude incompatible activities)
- Exclude activities with difficulty far above child's level

**Step 2 — Score Activities**:
- +2 if primary_target matches top 2 goals' profile_domain_id
- +1 for secondary_targets matching goals' profile_domain_id
- +1 if activity target_tags overlap with goal target_tags
- +1 if language requirement ≤ child's expressive/receptive level
- +1 if activity fits high-priority context from parent preferences
- −2 if last 3 enjoyment logs were thumbs_down
- +1 if last log was thumbs_up (capped)
- −1 if activity was used within last 2 days

**Step 3 — Select 3 Recommendations**:
1. **Anchor Favorite** – high enjoyment + high score
2. **Goal-Focused Stretch** – matches goals, not recently used
3. **Novelty Option** – new or not used in a long time

#### 2. Daily Recommendations

- Recommendations computed once daily per child
- Cached in `DailyRecommendation` model (child_profile_id, date, activity_template_ids)
- Background job runs daily at 6 AM to compute for all active children
- On-demand fallback if no recommendation exists for today or job failed

#### 3. Recommendations UI

- Today's recommendations view (3 activity cards)
- Activity detail view (from recommendations)
- Navigation from recommendations to activity detail

### Implementation Notes (Phase 2b)

- Create `daily_recommendations` table
- Implement `ActivityRecommendationService` with filtering, scoring, selection logic
- Implement `DailyRecommendationJob` (minimal, with error handling)
- Create `ActivitiesController` and views
- Add routing for recommendations

---

## Phase 2c: Activity Logging

**Goal**: Enable parents to quickly log activity attempts with completion and enjoyment.

**Deliverable**: Parent can log activities after doing them, with fast completion/enjoyment tracking.

### User Stories (Phase 2c)

9. I can log an activity after doing it
10. I can mark if we completed it (✅ / ❌)
11. I can rate enjoyment (👍 / 😐 / 👎)
12. I can add an optional quick note
13. I can adjust when the activity happened (defaults to now)

### Features (Phase 2c)

#### 1. Activity Logging

**Log Fields**:
- Child profile
- Activity template
- Occurred at (datetime, defaults to now)
- Completed (boolean)
- Enjoyment (thumbs_up, neutral, thumbs_down)
- Note (optional text)

**Derived Metrics** (for recommendation engine):
- Completion rate per activity
- Average enjoyment per activity
- Aggregates by target, duration, context

#### 2. Logging UI

- Logging form on activity detail page (after viewing activity)
- Quick logging interface (completion + enjoyment + optional note)
- Date/time picker for occurred_at
- Success feedback after logging

#### 3. Log History

- Basic log history view (for parent to see past logs)
- Simple list of logged activities with date, completion, enjoyment

### Implementation Notes (Phase 2c)

- Create `activity_logs` table
- Implement `ActivityLoggingService`
- Create `ActivityLogsController`
- Add logging form to activity detail view
- Add log history view
- Update recommendation engine to use log data for scoring

---

## Phase 2d: Weekly Feedback

**Goal**: Provide minimal weekly summary with insights to parents.

**Deliverable**: Parent can view weekly summary showing activity patterns and simple insights.

### User Stories (Phase 2d)

14. I can view a weekly summary of our activities
15. I can see how many activities we attempted
16. I can see which target types my child enjoyed most
17. I can see patterns by duration (5 min vs 10 min)
18. I can see simple text insights about our activity patterns

### Features (Phase 2d)

#### 1. Weekly Summary

**Summary Content**:
- Number of activities attempted
- Number of activities completed
- Completion rate
- Most enjoyed target types (ProfileDomains with highest enjoyment)
- Patterns by duration (5 min vs 10 min completion/enjoyment)
- Simple text insights (e.g., "She enjoyed sensory play more than turn-taking games.")

**Optional** (not required for Phase 2):
- One simple bar chart

#### 2. Summary Generation

- Generate on-demand when parent views weekly summary
- Cache in `AiDocument` with `document_type: 'weekly_summary'`
- Key by child_profile_id + week_start_date + content checksum
- Check updated_at to determine if regeneration needed

#### 3. Summary UI

- Weekly summary view
- Week selector (view different weeks)
- Clean, readable summary display
- No dashboards, just summary

### Implementation Notes (Phase 2d)

- Implement `WeeklySummaryService` with insights generation
- Create `WeeklySummariesController`
- Create weekly summary view
- Add week navigation/selector
- Cache summaries in AiDocument

---

## Database Schema Summary

### New Tables

- `activity_templates` - Activity cards with metadata
- `activity_logs` - Activity attempt records
- `daily_recommendations` - Cached daily recommendations

### Extended Tables

- `child_profiles` - Add `preferred_contexts` JSONB
- `child_domain_profiles` - Add language/sensory fields
- `child_goals` - Add `target_tags` JSONB

---

## UI/UX Requirements

### Design Principles
- **Fast**: Logging should take < 30 seconds
- **Simple**: Minimal clicks, clear actions
- **Supportive**: Positive framing, celebrate attempts
- **Mobile-friendly**: Works well on phone

### Activity Cards
- Recipe-card style UI
- Clear materials list
- Readable parent script
- Easy-to-scan variation

### Logging Interface
- Large, tappable buttons for completion/enjoyment
- Optional note field (not required)
- Quick date/time adjustment
- Immediate success feedback

### Weekly Summary
- Clean, scannable layout
- Simple insights in plain language
- Week navigation
- Print-friendly styling

---

## Success Metrics

### Phase 2a Success Metrics
- Activity templates seeded and displayable
- Profile generation extracts language/sensory data correctly
- Parent context preferences captured

### Phase 2b Success Metrics
- Recommendations generated daily for all active children
- Recommendations show variety (not always same 3)
- Recommendations match child's profile
- Page load < 2 seconds

### Phase 2c Success Metrics
- Parents log at least 1 activity per week
- Logging takes < 30 seconds
- Completion rate > 50%
- Log data feeds into recommendation scoring

### Phase 2d Success Metrics
- Parents view weekly summary at least once per month
- Summary insights are accurate and helpful
- Summary generation < 5 seconds

---

## Non-Goals for Phase 2

- No advanced AI recommendation logic
- No therapist portal
- No complex analytics dashboards
- No multi-child trend analysis
- No custom activity creation by parents
- No activity sharing between families
- No video/photo logging

Phase 2 is about creating a **usable, testable daily loop**.

---

## Future Enhancements (Post-Phase 2)

- AI-powered recommendation ranking
- Custom activity creation by parents/therapists
- Activity templates admin interface enhancements
- Advanced analytics and trends
- Multi-child comparison
- Therapist activity assignment
- Activity sharing between families
- Video/photo logging
- Activity difficulty auto-adjustment based on logs
- AI-rewritten parent scripts
- AI-generated weekly summaries
- AI-generated activity variations

---

## Testing Requirements

### Phase 2a Testing
- Activity templates display correctly
- Profile generation extracts language/sensory data
- Parent context preferences save correctly

### Phase 2b Testing
- Recommendation algorithm filters correctly
- Recommendation algorithm scores correctly
- Daily recommendations cache correctly
- Background job runs successfully

### Phase 2c Testing
- Activity logging saves correctly
- Log data feeds into recommendation scoring
- Log history displays correctly

### Phase 2d Testing
- Weekly summary generates correctly
- Summary insights are accurate
- Summary caching works correctly
