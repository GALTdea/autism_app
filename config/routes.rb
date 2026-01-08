Rails.application.routes.draw do
  draw :madmin

  root "pages#home"
  devise_for :users

  # Admin routes (custom admin dashboard and features)
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Custom admin resources
    resources :child_profiles, only: [ :index, :show ] do
      member do
        get :onboarding_sessions
        get :activity_logs
      end
    end

    resources :onboarding_sessions, only: [ :index, :show ] do
      member do
        post :regenerate_profile
      end
    end

    resources :activity_logs, only: [ :index ]
    resources :analytics, only: [ :index ]
    resources :questions, only: [ :index ]

    # Standalone AssessmentDomains (question banks/templates)
    resources :assessment_domains do
      member do
        get :manage_questions
        post :create_question
        patch :update_question
        delete :destroy_question
        patch :reorder_questions
        get :preview
        post :clone
      end

      # Nested question resources for question options
      resources :questions, only: [ :new, :edit ], controller: "assessment_domains/questions" do
        resources :question_options, only: [ :create, :update, :destroy ], param: :option_id, controller: "assessment_domains/question_options" do
          collection do
            patch :reorder
          end
        end
      end
    end

    resources :assessments do
      # Assessment Builder wizard routes
      member do
        get :select_domains
        patch :update_domains
        get :order_domains
        patch :reorder_domains
        get :preview
        post :clone
        get :configure_scoring
        post :clone_domain_for_assessment
      end

      # Manage questions through assessment sections (assessment_domains)
      resources :assessment_domains, only: [], param: :section_id do
        member do
          get :manage_questions
          post :create_question
          patch :update_question
          delete :destroy_question
          patch :reorder_questions
          get :preview_questions
        end

        # Nested question resources
        resources :questions, only: [], controller: "assessments/questions" do
          member do
            get :edit_form
            post :clone
          end
          collection do
            post :create_from_template
            get :templates
            get :copy_from_section_form
            post :copy_from_section
            get :import_csv_form
            post :import_csv
            get :csv_template
          end
          resources :question_options, only: [ :create, :update, :destroy ], param: :option_id, controller: "assessments/question_options" do
            collection do
              patch :reorder
            end
          end
        end
      end
    end

    resources :profile_domains do
      # Domain Builder wizard routes
      member do
        get :manage_questions
        post :create_question
        patch :update_question
        delete :destroy_question
        patch :reorder_questions
        get :preview
      end

      # Nested question resources for question options
      resources :questions, only: [], controller: "profile_domains/questions" do
        member do
          get :edit_form
          post :clone
        end
        collection do
          post :create_from_template
          get :templates
          get :copy_from_domain_form
          post :copy_from_domain
          get :import_csv_form
          post :import_csv
          get :csv_template
        end
        resources :question_options, only: [ :create, :update, :destroy ], param: :option_id do
          collection do
            patch :reorder
          end
        end
      end
    end
  end

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

    # Activity Logs (Phase 2c)
    resources :activity_logs, only: [ :create, :index ]
  end

  # Activity Templates (Phase 2a)
  resources :activity_templates, only: [ :index, :show ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
