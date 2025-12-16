module Admin
  class AssessmentsController < Admin::ApplicationController
    before_action :set_assessment, only: [:show, :edit, :update, :destroy]
    after_action :verify_authorized

    def index
      @assessments = policy_scope(Assessment).includes(:profile_domains, :onboarding_sessions)
                                             .order(name: :asc, version: :desc)
      authorize [:admin, Assessment]
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
        redirect_to admin_assessment_path(@assessment),
                    notice: "Assessment created successfully."
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

    private

    def set_assessment
      @assessment = Assessment.find(params[:id])
    end

    def assessment_params
      params.require(:assessment).permit(:name, :version, :description, :active, :is_default)
    end
  end
end
