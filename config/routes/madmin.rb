# Below are the routes for madmin
namespace :madmin do
  resources :users
  resources :questions
  resources :question_options
  resources :onboarding_sessions
  resources :profile_domains
  resources :activity_logs
  resources :activity_templates
  resources :ai_documents
  resources :answers
  resources :assessments
  resources :assessment_domains
  resources :child_domain_profiles
  resources :child_goals
  resources :child_memberships
  resources :child_profiles
  resources :daily_recommendations
  root to: "dashboard#show"
end
