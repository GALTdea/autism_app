# Phase 1 Testing Guide - Assessment Feature

This guide covers how to test that Phase 1 (Assessment feature) was completed properly.

## Prerequisites

1. Run migrations:
   ```bash
   bin/rails db:migrate
   ```

2. Run seeds (optional, but recommended):
   ```bash
   bin/rails db:seed
   ```

## Testing Checklist

### 1. Database Structure ✅

**Test migrations:**
```bash
bin/rails db:migrate:status
```

Should show all 4 new migrations as "up":
- CreateAssessments
- CreateAssessmentDomains
- AddAssessmentToOnboardingSessions
- BackfillOnboardingSessionsWithDefaultAssessment

**Verify tables exist:**
```bash
bin/rails runner "puts Assessment.table_exists? && AssessmentDomain.table_exists?"
# Should output: true
```

**Check schema:**
```bash
bin/rails db:schema:dump
# Check db/schema.rb for assessments and assessment_domains tables
```

### 2. Seed Data ✅

**Run seeds:**
```bash
bin/rails db:seed
```

**Expected output:**
```
Seeding Assessments...
  ✓ Full Assessment v1.0 (5 domains)
  ✓ Quick Assessment v1.0 (2 domains)

✓ Seed data complete!
  ...
  - 2 assessments
```

**Verify in Rails console:**
```ruby
rails console

# Check assessments exist
Assessment.count
# => 2

# Check default assessment
Assessment.default.first
# => #<Assessment id: 1, name: "Full Assessment", version: "1.0", is_default: true>

# Check domains are assigned
Assessment.default.first.domain_count
# => 5

# Check Quick Assessment
quick = Assessment.find_by(name: "Quick Assessment")
quick.domain_count
# => 2
quick.profile_domains.pluck(:key)
# => ["communication", "sensory"]
```

### 3. Model Tests ✅

**Run model tests:**
```bash
bin/rails test test/models/assessment_test.rb
bin/rails test test/models/assessment_domain_test.rb
```

**Manual model testing in Rails console:**
```ruby
rails console

# Test Assessment model
assessment = Assessment.default.first

# Test associations
assessment.profile_domains.count
assessment.assessment_domains.count
assessment.onboarding_sessions.count

# Test methods
assessment.domain_count
assessment.ordered_domains
assessment.activate!
assessment.deactivate!

# Test domain management
domain = ProfileDomain.first
assessment.add_domain(domain)
assessment.remove_domain(domain)

# Test AssessmentDomain model
ad = AssessmentDomain.first
ad.assessment
ad.profile_domain
```

### 4. Service Tests ✅

**Test OnboardingService:**

```ruby
rails console

# Create test user and child profile
user = User.first
child = ChildProfile.first

# Start session - should assign assessment
session = OnboardingService.start_session(user, child)
session.assessment
# => Should return Assessment object

# Verify default assessment is assigned
session.assessment.name
# => "Full Assessment"
```

**Test ProfileGenerationService:**

```ruby
rails console

# Get a completed onboarding session
session = OnboardingSession.completed.first

# Generate profile - should use assessment domains
ProfileGenerationService.generate_profile(session.child_profile, session)

# Check domain profiles were created only for assessment domains
session.assessment.profile_domains.count
session.child_profile.child_domain_profiles.count
# Should match (or be less if some domains had no answers)
```

### 5. Controller Tests ✅

**Manual browser testing:**

1. **Start onboarding:**
   - Navigate to child profile
   - Click "Start Onboarding"
   - Verify it redirects to onboarding page

2. **Check domain order:**
   - Verify domains appear in the order defined by assessment
   - Check step counter shows correct total (should match assessment.domain_count)

3. **Complete onboarding:**
   - Answer questions for all domains in assessment
   - Complete onboarding
   - Verify profile is generated

**Test in Rails console:**
```ruby
rails console

# Simulate controller behavior
session = OnboardingSession.in_progress.first
assessment = session.assessment || Assessment.default.first

# Check domains are ordered correctly
assessment.ordered_domains.pluck(:label)
# Should match the order in assessment_domains.position

# Check total steps calculation
assessment.domain_count
# Should match what controller shows
```

### 6. Backward Compatibility ✅

**Test that existing sessions work:**

```ruby
rails console

# Create session without assessment (simulating old data)
session = OnboardingSession.create!(
  child_profile: ChildProfile.first,
  user: User.first,
  status: 'in_progress',
  assessment: nil
)

# Verify fallback works
session.assessment || Assessment.default.first
# Should return default assessment

# Test progress calculation
session.progress_percentage
# Should work even without assessment
```

### 7. Assessment Management ✅

**Test creating new assessments:**

```ruby
rails console

# Create new assessment
new_assessment = Assessment.create!(
  name: "Test Assessment",
  version: "1.0",
  description: "Test",
  active: true,
  is_default: false
)

# Add domains
comm = ProfileDomain.find_by(key: "communication")
social = ProfileDomain.find_by(key: "social")
new_assessment.add_domain(comm, position: 0)
new_assessment.add_domain(social, position: 1)

# Verify
new_assessment.domain_count
# => 2

# Activate it
new_assessment.activate!
Assessment.default.first.name
# => "Test Assessment"
```

### 8. Integration Test ✅

**Full flow test:**

```ruby
rails console

# 1. Create user and child
user = User.create!(email: "test@example.com", password: "password123")
child = ChildProfile.create!(
  name: "Test Child",
  birth_date: 5.years.ago,
  primary_caregiver: user
)

# 2. Start onboarding (should assign assessment)
session = OnboardingService.start_session(user, child)
puts "Assessment assigned: #{session.assessment.name}"
puts "Domains in assessment: #{session.assessment.domain_count}"

# 3. Answer some questions
questions = session.assessment.ordered_domains.first.questions.limit(2)
questions.each do |q|
  option = q.question_options.first
  OnboardingService.save_answer(session, q.id, { question_option_id: option.id })
end

# 4. Check progress
puts "Progress: #{session.progress_percentage}%"

# 5. Complete session
OnboardingService.complete_session(session)

# 6. Verify profile was generated
puts "Domain profiles created: #{child.child_domain_profiles.count}"
```

## Automated Tests

Run the test suite:
```bash
bin/rails test
```

Or run specific test files:
```bash
bin/rails test test/models/assessment_test.rb
bin/rails test test/models/assessment_domain_test.rb
bin/rails test test/services/onboarding_service_test.rb
bin/rails test test/controllers/onboarding_controller_test.rb
```

## Common Issues & Solutions

### Issue: "Assessment not found" errors
**Solution:** Run seeds to create default assessment:
```bash
bin/rails db:seed
```

### Issue: Domains not in correct order
**Solution:** Check assessment_domains.position values:
```ruby
Assessment.first.assessment_domains.ordered.pluck(:position, :profile_domain_id)
```

### Issue: Old sessions don't have assessments
**Solution:** Run the backfill migration or manually assign:
```ruby
OnboardingSession.where(assessment_id: nil).update_all(assessment_id: Assessment.default.first.id)
```

## Success Criteria

✅ All migrations run successfully  
✅ Seed data creates 2 assessments  
✅ Default assessment has all 5 domains  
✅ Quick assessment has 2 domains  
✅ New onboarding sessions get default assessment  
✅ Profile generation uses assessment domains  
✅ Controller shows domains in assessment order  
✅ Backward compatibility works (sessions without assessment)  
✅ Assessment management methods work correctly  

## Next Steps

Once Phase 1 is verified:
- Proceed to Phase 2: Scoring Configuration
- Or start using assessments in production


