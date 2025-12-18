module Admin
  class ProfileDomainsController < Admin::ApplicationController
    before_action :set_profile_domain, only: [ :show, :edit, :update, :destroy,
                                              :manage_questions, :reorder_questions, :preview ]
    after_action :verify_authorized

    def index
      authorize [ :admin, ProfileDomain ]
      @profile_domains = policy_scope([ :admin, ProfileDomain ]).includes(:questions, :assessments)
                                                                 .order(:label)
    end

    def show
      authorize [ :admin, @profile_domain ]
      @questions = @profile_domain.questions.includes(:question_options).ordered
      # Count onboarding sessions that use assessments containing this domain
      assessment_ids = @profile_domain.assessments.pluck(:id)
      @stats = {
        total_questions: @profile_domain.questions.count,
        total_assessments: @profile_domain.assessments.count,
        total_child_profiles: @profile_domain.child_profiles.count,
        total_onboarding_sessions: assessment_ids.any? ? OnboardingSession.where(assessment_id: assessment_ids).distinct.count : 0
      }
    end

    def new
      @profile_domain = ProfileDomain.new
      authorize [ :admin, @profile_domain ]
    end

    def create
      @profile_domain = ProfileDomain.new(profile_domain_params)
      authorize [ :admin, @profile_domain ]

      if @profile_domain.save
        redirect_to admin_profile_domain_path(@profile_domain),
                    notice: "Profile domain created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize [ :admin, @profile_domain ]
      @questions = @profile_domain.questions.ordered if @profile_domain.questions.any?
    end

    def update
      authorize [ :admin, @profile_domain ]

      if @profile_domain.update(profile_domain_params)
        redirect_to admin_profile_domain_path(@profile_domain),
                    notice: "Profile domain updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [ :admin, @profile_domain ]

      if can_be_deleted?
        @profile_domain.destroy
        redirect_to admin_profile_domains_path,
                    notice: "Profile domain deleted successfully."
      else
        redirect_to admin_profile_domains_path,
                    alert: "Cannot delete profile domain. It is being used in assessments, child profiles, or has questions."
      end
    end

    private

    def set_profile_domain
      @profile_domain = ProfileDomain.find(params[:id])
    end

    def profile_domain_params
      params.require(:profile_domain).permit(:key, :label, :description)
    end

    def can_be_deleted?
      # Check if domain is in use
      return false if @profile_domain.assessments.any?
      return false if @profile_domain.child_profiles.any?
      return false if @profile_domain.questions.any?
      true
    end
  end
end
