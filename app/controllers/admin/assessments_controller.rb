module Admin
  class AssessmentsController < Admin::ApplicationController
    before_action :set_assessment, only: [:show, :edit, :update, :destroy,
                                          :select_domains, :update_domains,
                                          :order_domains, :reorder_domains,
                                          :preview, :clone]
    after_action :verify_authorized

    def index
      authorize [:admin, Assessment]
      @assessments = policy_scope([:admin, Assessment]).includes(:profile_domains, :onboarding_sessions)
                                                        .order(name: :asc, version: :desc)
    end

    def show
      authorize [:admin, @assessment]
      @domains = @assessment.ordered_domains.includes(:questions)
      @stats = {
        total_questions: @assessment.total_questions_count,
        total_sessions: @assessment.onboarding_sessions.count,
        active_sessions: @assessment.onboarding_sessions.in_progress.count,
        completed_sessions: @assessment.onboarding_sessions.completed.count
      }
    end

    def new
      @assessment = Assessment.new
      authorize [:admin, @assessment]
    end

    def create
      @assessment = Assessment.new(assessment_params)
      authorize [:admin, @assessment]

      if @assessment.save
        redirect_to select_domains_admin_assessment_path(@assessment),
                    notice: "Assessment created. Now select domains."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize [:admin, @assessment]
    end

    def update
      authorize [:admin, @assessment]

      if @assessment.update(assessment_params)
        redirect_to admin_assessment_path(@assessment),
                    notice: "Assessment updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [:admin, @assessment]

      if @assessment.can_be_deleted?
        @assessment.destroy
        redirect_to admin_assessments_path,
                    notice: "Assessment deleted successfully."
      else
        redirect_to admin_assessments_path,
                    alert: "Cannot delete assessment with existing onboarding sessions."
      end
    end

    # Assessment Builder Wizard Actions

    def select_domains
      authorize [:admin, @assessment]
      @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered
      @available_domains = ProfileDomain.ordered - @assessment.profile_domains
    end

    def update_domains
      authorize [:admin, @assessment]

      domain_ids = params[:domain_ids] || []

      begin
        AssessmentDomainService.update_domains(@assessment, domain_ids)
        redirect_to order_domains_admin_assessment_path(@assessment),
                    notice: "Domains updated successfully."
      rescue AssessmentDomainService::Error => e
        redirect_to select_domains_admin_assessment_path(@assessment),
                    alert: "Failed to update domains: #{e.message}"
      end
    end

    def order_domains
      authorize [:admin, @assessment]
      @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered
      redirect_to select_domains_admin_assessment_path(@assessment),
                  alert: "Please select at least one domain first." if @assessment_domains.empty?
    end

    def reorder_domains
      authorize [:admin, @assessment]

      domain_positions = params[:domain_positions] || {}

      begin
        AssessmentDomainService.reorder_domains(@assessment, domain_positions)

        if request.format.json?
          render json: { status: "success", message: "Domain order updated successfully." }
        else
          redirect_to order_domains_admin_assessment_path(@assessment),
                      notice: "Domain order updated successfully."
        end
      rescue AssessmentDomainService::Error => e
        if request.format.json?
          render json: { status: "error", message: e.message }, status: :unprocessable_entity
        else
          redirect_to order_domains_admin_assessment_path(@assessment),
                      alert: "Failed to reorder domains: #{e.message}"
        end
      end
    end

    def preview
      authorize [:admin, @assessment]
      @domains = @assessment.ordered_domains.includes(:questions)
      redirect_to select_domains_admin_assessment_path(@assessment),
                  alert: "Please select at least one domain first." if @domains.empty?
    end

    def clone
      authorize [:admin, @assessment]
      begin
        cloned_assessment = @assessment.clone
        redirect_to edit_admin_assessment_path(cloned_assessment),
                    notice: "Assessment cloned successfully. Update version and details."
      rescue AssessmentCloningService::Error => e
        redirect_to admin_assessments_path,
                    alert: "Failed to clone assessment: #{e.message}"
      end
    end

    private

    def set_assessment
      @assessment = Assessment.find(params[:id])
    end

    def assessment_params
      params.require(:assessment).permit(:name, :version, :description, :active, :is_default)
    end
  end
end
