# Phase 2a Testing Guide

## Quick Test Checklist

### ✅ Test 1: View Activity Templates

**Goal**: Verify activity templates are seeded and displayable

1. Start the Rails server:
   ```bash
   bin/rails server
   ```

2. Sign in to the app (or create a new account)

3. Navigate to: `http://localhost:3000/activity_templates`

4. **Expected Results**:
   - See a grid of activity cards (22 activities)
   - Each card shows: title, target domain, duration (5 or 10 min)
   - Cards are clickable

5. Click on any activity card

6. **Expected Results**:
   - See full activity details page
   - Shows: Title, Target, Duration
   - Shows: Materials Needed section
   - Shows: Parent Script section (blue background)
   - Shows: Simple Variation section (green background)

---

### ✅ Test 2: Verify Activity Template Data

**Goal**: Check that activity templates have proper metadata

1. Open Rails console:
   ```bash
   bin/rails console
   ```

2. Check activity count:
   ```ruby
   ActivityTemplate.count
   # Should return: 22
   ```

3. Check activities by domain:
   ```ruby
   ActivityTemplate.joins(:primary_target).group('profile_domains.label').count
   # Should show activities across 5 domains
   ```

4. Check a specific activity's metadata:
   ```ruby
   activity = ActivityTemplate.first
   activity.title
   activity.duration_minutes
   activity.age_bands
   activity.target_tags
   activity.contexts
   # All should have proper values
   ```

5. Check age band helper:
   ```ruby
   ActivityTemplate.age_band_for_age(4)  # Should return "3-5"
   ActivityTemplate.age_band_for_age(7)  # Should return "6-8"
   ActivityTemplate.age_band_for_age(10) # Should return "9-11"
   ```

---

### ✅ Test 3: Profile Generation with Language/Sensory Extraction

**Goal**: Verify that onboarding extracts language and sensory profiles

1. **Create a new child profile**:
   - Navigate to: `http://localhost:3000/child_profiles/new`
   - Fill in: Name, Birth Date
   - Click "Create Child Profile"

2. **Start onboarding**:
   - On the child profile page, click "Start Onboarding"
   - Complete all questions for all domains

3. **Complete onboarding**:
   - After answering all questions, click "Complete Onboarding"
   - You should be redirected to the child profile page

4. **Verify language profile extraction** (Rails console):
   ```ruby
   child = ChildProfile.last
   comm_profile = child.child_domain_profiles.joins(:profile_domain).find_by(profile_domains: { key: 'communication' })
   
   # Check language levels
   comm_profile.expressive_level  # Should be: pre_verbal, single_words, short_phrases, or sentences
   comm_profile.receptive_level   # Should be: pre_verbal, single_words, short_phrases, or sentences
   comm_profile.supports          # Should be an array (may include "visual_supports")
   ```

5. **Verify sensory profile extraction**:
   ```ruby
   sensory_profile = child.child_domain_profiles.joins(:profile_domain).find_by(profile_domains: { key: 'sensory' })
   
   # Check sensory levels
   sensory_profile.seeking_level     # Should be 0-5
   sensory_profile.avoiding_level    # Should be 0-5
   sensory_profile.sensitivity_tags  # Should be an array (may include "avoids_loud_noise", "texture_sensitivity", "seeks_movement")
   ```

6. **Test helper methods**:
   ```ruby
   child.language_profile
   # Should return: { expressive_level: "...", receptive_level: "...", supports: [...] }
   
   child.sensory_profile
   # Should return: { seeking_level: ..., avoiding_level: ..., sensitivity_tags: [...] }
   
   child.age
   # Should return child's age in years
   
   child.age_band
   # Should return: "3-5", "6-8", or "9-11" based on age
   ```

---

### ✅ Test 4: Child Profile Extensions

**Goal**: Verify new fields are available

1. **Check preferred_contexts** (Rails console):
   ```ruby
   child = ChildProfile.last
   child.preferred_contexts  # Should be [] by default (can be set later)
   ```

2. **Check child goals with target_tags**:
   ```ruby
   goal = child.child_goals.first
   goal.target_tags  # Should be [] by default (can be set later)
   ```

---

### ✅ Test 5: Activity Template Scopes

**Goal**: Test filtering and querying

1. **Test active scope**:
   ```ruby
   ActivityTemplate.active.count  # Should return 22
   ```

2. **Test age filtering** (note: SQLite JSON querying is limited):
   ```ruby
   # This may not work perfectly in SQLite, but should not error
   ActivityTemplate.for_age(4).count
   ```

3. **Test duration filtering**:
   ```ruby
   ActivityTemplate.for_duration(5).count   # Should return some activities
   ActivityTemplate.for_duration(10).count  # Should return some activities
   ```

4. **Test difficulty filtering**:
   ```ruby
   ActivityTemplate.for_difficulty(2).count  # Should return activities with difficulty <= 2
   ```

5. **Test energy level filtering**:
   ```ruby
   ActivityTemplate.for_energy_level('calming').count     # Should return some
   ActivityTemplate.for_energy_level('energizing').count  # Should return some
   ActivityTemplate.for_energy_level('neutral').count     # Should return most
   ```

---

### ✅ Test 6: Activity Template Helper Methods

**Goal**: Test utility methods

1. **Test script_for_level**:
   ```ruby
   activity = ActivityTemplate.first
   activity.script_for_level('single_words')  # Should return script or parent_script
   ```

2. **Test matches_target_tags**:
   ```ruby
   activity = ActivityTemplate.where("json_extract(target_tags, '$') LIKE ?", "%turn_taking%").first
   activity.matches_target_tags?(['turn_taking', 'waiting'])  # Should return true if tags overlap
   ```

---

## Manual UI Testing Flow

### Complete End-to-End Test

1. **Start fresh**:
   ```bash
   bin/rails db:reset  # Resets and seeds database
   bin/rails server
   ```

2. **Sign up/Login**:
   - Go to: `http://localhost:3000`
   - Sign up or log in

3. **Create child profile**:
   - Click "Add Child" or go to `/child_profiles/new`
   - Enter: Name (e.g., "Alex"), Birth Date (e.g., 5 years ago)
   - Save

4. **View activities** (before onboarding):
   - Navigate to `/activity_templates`
   - Browse activities
   - Click on a few to see details
   - ✅ Verify all visible fields display correctly

5. **Complete onboarding**:
   - On child profile page, click "Start Onboarding"
   - Answer all questions for each domain:
     - Communication (4 questions)
     - Social & Play (3 questions)
     - Flexibility & Behavior (3 questions)
     - Sensory Processing (3 questions)
     - Emotional Regulation (3 questions)
     - Parent Priorities (1 question)
   - Click "Complete Onboarding"

6. **Verify profile generation**:
   - You should see the child profile with:
     - Domain scores
     - Strengths and challenges
     - Suggested goals
   - ✅ Profile should be generated successfully

7. **Check extracted data** (Rails console):
   ```ruby
   child = ChildProfile.last
   
   # Language profile
   puts "Expressive: #{child.language_profile[:expressive_level]}"
   puts "Receptive: #{child.language_profile[:receptive_level]}"
   puts "Supports: #{child.language_profile[:supports]}"
   
   # Sensory profile
   puts "Seeking: #{child.sensory_profile[:seeking_level]}"
   puts "Avoiding: #{child.sensory_profile[:avoiding_level]}"
   puts "Tags: #{child.sensory_profile[:sensitivity_tags]}"
   ```

---

## Common Issues & Solutions

### Issue: Activities not showing
- **Check**: Run `bin/rails db:seed` to ensure activities are seeded
- **Check**: Verify `ActivityTemplate.count` returns 22

### Issue: Language/sensory profiles not extracted
- **Check**: Ensure you completed ALL onboarding questions
- **Check**: Verify answers exist: `OnboardingSession.last.answers.count`
- **Check**: Look for specific question codes: `Answer.joins(:question).where(questions: { code: 'COMM_1' })`

### Issue: JSON fields showing as strings
- **Normal**: SQLite stores JSON as text, but Rails should parse it automatically
- **Check**: `activity.age_bands.class` should be `Array` (not String)

### Issue: Routes not working
- **Check**: Routes file should have: `resources :activity_templates, only: [:index, :show]`
- **Check**: Remove duplicate route definitions if present

---

## Database Verification Queries

Run these in Rails console to verify everything is set up correctly:

```ruby
# Check migrations ran
ActiveRecord::Base.connection.table_exists?('activity_templates')
ActiveRecord::Base.connection.column_exists?(:child_domain_profiles, :expressive_level)
ActiveRecord::Base.connection.column_exists?(:child_profiles, :preferred_contexts)
ActiveRecord::Base.connection.column_exists?(:child_goals, :target_tags)

# Check activity templates
ActivityTemplate.count  # Should be 22
ActivityTemplate.active.count  # Should be 22
ActivityTemplate.joins(:primary_target).group('profile_domains.key').count

# Check a sample activity
activity = ActivityTemplate.first
activity.primary_target.label
activity.duration_minutes
activity.age_bands
activity.target_tags
```

---

## Success Criteria

✅ **Phase 2a is complete when**:
1. All 22 activity templates are seeded and viewable
2. Activity index page shows all activities in a grid
3. Activity show page displays all visible fields correctly
4. Onboarding completion extracts language profile (expressive_level, receptive_level, supports)
5. Onboarding completion extracts sensory profile (seeking_level, avoiding_level, sensitivity_tags)
6. ChildProfile helper methods work (age, age_band, language_profile, sensory_profile, top_goals)
7. All database fields are accessible and store data correctly

---

## Next Steps After Testing

Once Phase 2a is verified:
- ✅ Move to Phase 2b: Recommendation Engine & Daily Recommendations
- ✅ Activities are ready to be used in recommendations
- ✅ Profile data is ready to inform recommendation algorithm





