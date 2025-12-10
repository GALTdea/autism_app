Rails.application.routes.draw do
  root "pages#home"
  devise_for :users

  # Child Profiles
  resources :child_profiles, only: [:new, :create, :show] do
    # Onboarding flow
    resources :onboarding, only: [:show, :update], controller: 'onboarding'
    member do
      get 'onboarding/start', to: 'onboarding#start', as: :start_onboarding
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
