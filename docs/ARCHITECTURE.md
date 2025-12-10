# Architecture Documentation

## Overview

This document describes the architecture of the Autism Therapy App, an AI-powered home therapy companion for autistic children.

## System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                      │
│  (Hotwire/Turbo + Stimulus + Tailwind CSS + Flowbite)        │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Controller Layer                           │
│  (Rails Controllers + Pundit Policies)                        │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                              │
│  (OnboardingService, ProfileGenerationService, etc.)         │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer                                │
│  (ActiveRecord Models + Associations)                         │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Database Layer                             │
│  (SQLite dev / PostgreSQL production)                         │
└─────────────────────────────────────────────────────────────┘
```

## Domain Model

### Core Entities

#### User
- Represents a person using the system (parent, therapist, caregiver)
- Authenticated via Devise
- Has a global role enum (user, admin, super_admin) - optional
- Can have multiple `ChildMembership` records (access to multiple children)

#### ChildProfile
- Represents a child receiving therapy
- Owned by a primary caregiver (User)
- Contains basic info: name, birth_date, diagnosis_summary
- Has many domain profiles, goals, onboarding sessions

#### ChildMembership
- Join table between User and ChildProfile
- Defines user's role for a specific child: `parent`, `therapist`, `co_parent`, `caregiver`
- One membership per child is marked `is_primary` (primary caregiver)
- Used for authorization (who can see/edit what)

#### OnboardingSession
- Tracks a parent's progress through the onboarding questionnaire
- Status: `in_progress`, `completed`
- Belongs to a child profile and user
- Has many answers

#### Question & QuestionOption
- Questions organized by domain (communication, social, flexibility, etc.)
- Questions have response types: `scale`, `multi_choice`, `text`
- Options have labels and numeric values for scoring

#### Answer
- Stores responses to questions during onboarding
- Can reference a question_option (for structured answers)
- Has numeric_value (denormalized for easy querying)
- Has free_text for open-ended responses

#### ProfileDomain
- Defines assessment domains: communication, social, flexibility, sensory, etc.
- Used to organize questions and profile analysis

#### ChildDomainProfile
- Stores domain-specific assessment for a child
- Contains level_estimate (0-3 or 0-5 scale)
- Contains strengths_summary and needs_summary
- Generated from onboarding answers

#### ChildGoal
- Therapy goals for a child
- Belongs to a child profile and profile domain
- Status: `suggested`, `active`, `paused`, `archived`
- Has priority ranking
- Generated from profile analysis

#### AiDocument
- Stores AI-generated content (profile summaries, recommendations)
- Document types: `profile_summary`, `onboarding_summary`, `weekly_summary`
- Stores markdown content
- Versioned by created_at

## Service Layer Architecture

### OnboardingService
**Purpose**: Handles the onboarding questionnaire flow and adaptive logic

**Responsibilities**:
- Manage onboarding session state
- Handle adaptive question logic (dependencies)
- Validate answers
- Complete onboarding and trigger profile generation

**Interface**:
```ruby
OnboardingService.start_session(user, child_profile)
OnboardingService.save_answer(session, question, answer_data)
OnboardingService.complete_session(session)
```

### ProfileGenerationService
**Purpose**: Generates initial child profile from onboarding answers

**Phase 1 Strategy**: Template-based
- Load template profiles from YAML/JSON
- Score answers against templates
- Generate domain profiles
- Create suggested goals

**Future Strategy**: AI-powered
- Same interface, but uses AI instead of templates
- Service designed to be AI-agnostic

**Interface**:
```ruby
ProfileGenerationService.generate_profile(child_profile, onboarding_session)
ProfileGenerationService.update_profile(child_profile, new_data)
```

### GoalRecommendationService
**Purpose**: Suggests therapy goals based on profile

**Interface**:
```ruby
GoalRecommendationService.suggest_goals(child_profile)
GoalRecommendationService.prioritize_goals(child_profile, parent_priorities)
```

## Authorization Model

### Pundit Policies

#### ChildProfilePolicy
- `show?`: User must have membership for child
- `update?`: Only primary caregiver or admin
- `destroy?`: Only primary caregiver

#### ChildMembershipPolicy
- `create?`: Only primary caregiver can invite
- `update?`: Only primary caregiver can change roles
- `destroy?`: Only primary caregiver can remove memberships

#### OnboardingSessionPolicy
- `show?`: User must have membership for child
- `update?`: Only parent/primary caregiver
- `complete?`: Only parent/primary caregiver

## Data Flow: Onboarding to Profile

```
1. User creates account → User model
2. User adds child → ChildProfile created, ChildMembership created (is_primary: true)
3. User starts onboarding → OnboardingSession created (status: in_progress)
4. User answers questions → Answer records created
5. User completes onboarding → OnboardingService.complete_session
   → ProfileGenerationService.generate_profile
   → ChildDomainProfile records created
   → ChildGoal records created (suggested status)
   → AiDocument created (profile_summary)
6. User views profile → Profile displayed with goals and insights
```

## Database Design Principles

### Indexes
- All foreign keys indexed
- Frequently queried fields indexed (status, role, is_primary)
- Composite indexes for common query patterns

### Soft Deletes
- `deleted_at` on `ChildProfile` and `ChildGoal` for data retention
- Use `paranoia` gem or custom scope

### Timestamps
- All tables have `created_at` and `updated_at`
- Use `timestamps` in migrations

### Constraints
- Foreign key constraints
- Unique constraints where appropriate (e.g., one primary caregiver per child)
- Not null constraints on required fields

## Background Jobs

### Solid Queue
- Profile generation (if slow, can be async)
- AI document generation (future)
- Email notifications (future)

## Frontend Architecture

### Hotwire (Turbo + Stimulus)
- **Turbo**: SPA-like navigation, form submissions, frames
- **Stimulus**: Interactive UI components (wizard, dropdowns, etc.)

### Component Structure
- Views organized by resource
- Partials for reusable components
- Stimulus controllers for interactive behavior

### Onboarding Wizard
- Multi-step form using Stimulus controller
- State managed in Stimulus
- Progress saved to OnboardingSession
- Can resume if interrupted

## Future Architecture Considerations

### Phase 2: Activities & Logging
- ActivityTemplate model
- ActivityLog model
- BehaviorLog model
- ActivityRecommendationService

### Phase 3: Multi-User Collaboration
- Real-time updates (Action Cable)
- Notification system
- Shared goal tracking

### Phase 4: Adaptive Coaching
- CoachingSession model
- CoachingService
- Real-time guidance generation

## Security Considerations

### Data Protection
- Sensitive health/developmental data
- Strong parameter filtering
- Authorization checks on all actions
- Consider encryption for sensitive fields
- Audit logging for sensitive operations

### Authentication
- Devise with secure password requirements
- Session management
- Password reset flow

### Authorization
- Pundit policies for all resources
- Role-based access control via ChildMembership
- Never trust client-side permissions

## Performance Considerations

### Database
- Eager loading to avoid N+1 queries
- Proper indexing strategy
- Query optimization

### Caching
- Fragment caching for profile views
- Cache AI documents
- Cache domain profiles

### Background Processing
- Use Solid Queue for heavy operations
- Async profile generation if needed

## Testing Strategy

### Test Coverage
- Models: validations, associations, scopes
- Controllers: actions, authorization, error handling
- Services: business logic, edge cases
- Policies: all permission checks
- Integration: key user flows

### Test Data
- FactoryBot for test fixtures
- Realistic test scenarios
- Edge case testing


