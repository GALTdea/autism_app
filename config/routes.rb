Rails.application.routes.draw do
  root "pages#home"
  devise_for :users

  # Child Profiles
  resources :child_profiles, only: [ :index, :new, :create, :show ] do
    # Onboarding flow
    member do
      get "onboarding/start", to: "onboarding#start", as: :start_onboarding
      get "onboarding", to: "onboarding#show", as: :onboarding
      patch "onboarding", to: "onboarding#update"
      post "onboarding/complete", to: "onboarding#complete", as: :complete_onboarding
    end

    # Activities (Phase 2b)
    resources :activities, only: [ :index ], controller: "activities"
  end

  # Activity Templates (Phase 2a)
  resources :activity_templates, only: [ :index, :show ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
