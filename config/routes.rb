Rails.application.routes.draw do
  root "pages#home"
  devise_for :users

  # Child Profiles
  resources :child_profiles, only: [:new, :create, :show] do
    # Onboarding flow
    member do
      get 'onboarding/start', to: 'onboarding#start', as: :start_onboarding
      get 'onboarding', to: 'onboarding#show', as: :onboarding
      patch 'onboarding', to: 'onboarding#update'
    end
    collection do
      post 'onboarding/complete', to: 'onboarding#complete', as: :complete_onboarding
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
