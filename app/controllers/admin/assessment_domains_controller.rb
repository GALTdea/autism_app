module Admin
  class AssessmentDomainsController < Admin::ApplicationController
    before_action :set_assessment_domain, only: [
      :show, :edit, :update, :destroy,
      :manage_questions, :create_question, :update_question,
      :destroy_question, :reorder_questions, :preview, :clone
    ]
    before_action :set_question, only: [ :update_question, :destroy_question ]
    after_action :verify_authorized

    def index
      authorize [ :admin, AssessmentDomain ]
      @assessment_domains = policy_scope([ :admin, AssessmentDomain ]).standalone
                                                                      .includes(:profile_domain, :questions)
                                                                      .order(:name, :version)
      @stats = {
        total_standalone: @assessment_domains.count,
        total_questions: @assessment_domains.sum { |ad| ad.questions.count },
        domains_with_questions: @assessment_domains.count(&:has_questions?)
      }
    end

    def show
      authorize [ :admin, @assessment_domain ]
      @questions = @assessment_domain.questions.includes(:question_options).ordered

      @stats = {
        total_questions: @questions.count,
        total_options: @questions.sum { |q| q.question_options.count },
        questions_with_options: @questions.count { |q| q.question_options.any? },
        questions_by_type: @questions.group_by(&:response_type).transform_values(&:count)
      }
    end

    def new
      @assessment_domain = AssessmentDomain.new
      authorize [ :admin, @assessment_domain ]
      @profile_domains = ProfileDomain.ordered
    end

    def create
      @assessment_domain = AssessmentDomain.new(assessment_domain_params)
      authorize [ :admin, @assessment_domain ]

      if @assessment_domain.save
        redirect_to admin_assessment_domain_path(@assessment_domain),
                    notice: "Assessment domain created successfully. You can now add questions."
      else
        @profile_domains = ProfileDomain.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize [ :admin, @assessment_domain ]
      @profile_domains = ProfileDomain.ordered
    end

    def update
      authorize [ :admin, @assessment_domain ]

      if @assessment_domain.update(assessment_domain_params)
        redirect_to admin_assessment_domain_path(@assessment_domain),
                    notice: "Assessment domain updated successfully."
      else
        @profile_domains = ProfileDomain.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [ :admin, @assessment_domain ]

      if @assessment_domain.standalone? && @assessment_domain.questions.empty?
        @assessment_domain.destroy
        redirect_to admin_assessment_domains_path,
                    notice: "Assessment domain deleted successfully."
      else
        redirect_to admin_assessment_domain_path(@assessment_domain),
                    alert: "Cannot delete assessment domain. It must be standalone and have no questions."
      end
    end

    def manage_questions
      authorize [ :admin, @assessment_domain ]
      @questions = @assessment_domain.questions.includes(:question_options).ordered
    end

    def create_question
      authorize [ :admin, @assessment_domain ]

      begin
        @question = QuestionManagementService.create_question(@assessment_domain, question_params)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        notice: "Question created successfully."
          }
          format.json { render json: { status: "success", question: @question }, status: :created }
          format.turbo_stream {
            @questions = @assessment_domain.questions.includes(:question_options).ordered
            render :create_question
          }
        end
      rescue QuestionManagementService::InvalidQuestionError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        alert: "Failed to create question: #{e.message}"
          }
          format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          format.turbo_stream {
            flash.now[:alert] = "Failed to create question: #{e.message}"
            render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
          }
        end
      end
    end

    def update_question
      authorize [ :admin, @assessment_domain ]

      begin
        QuestionManagementService.update_question(@question, question_params)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        notice: "Question updated successfully."
          }
          format.json { render json: { status: "success", question: @question.reload } }
          format.turbo_stream {
            @questions = @assessment_domain.questions.includes(:question_options).ordered
            render :update_question
          }
        end
      rescue QuestionManagementService::UpdateError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        alert: "Failed to update question: #{e.message}"
          }
          format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          format.turbo_stream {
            flash.now[:alert] = "Failed to update question: #{e.message}"
            render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
          }
        end
      end
    end

    def destroy_question
      authorize [ :admin, @assessment_domain ]

      begin
        QuestionManagementService.delete_question(@question)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        notice: "Question deleted successfully."
          }
          format.json { render json: { status: "success", message: "Question deleted successfully." } }
          format.turbo_stream {
            @questions = @assessment_domain.questions.includes(:question_options).ordered
            render :destroy_question
          }
        end
      rescue QuestionManagementService::DeleteError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        alert: "Failed to delete question: #{e.message}"
          }
          format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          format.turbo_stream {
            flash.now[:alert] = "Failed to delete question: #{e.message}"
            render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
          }
        end
      end
    end

    def reorder_questions
      authorize [ :admin, @assessment_domain ]

      question_positions = reorder_questions_params

      begin
        QuestionManagementService.reorder_questions(@assessment_domain, question_positions)

        @assessment_domain.reload
        @questions = @assessment_domain.questions.includes(:question_options).ordered

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        notice: "Question order updated successfully."
          }
          format.json { render json: { status: "success", message: "Question order updated successfully." } }
          format.turbo_stream {
            render :reorder_questions
          }
        end
      rescue QuestionManagementService::UpdateError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                        alert: "Failed to reorder questions: #{e.message}"
          }
          format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          format.turbo_stream {
            flash.now[:alert] = "Failed to reorder questions: #{e.message}"
            render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
          }
        end
      end
    end

    def preview
      authorize [ :admin, @assessment_domain ]
      @questions = @assessment_domain.questions.includes(:question_options).ordered

      if @questions.empty?
        redirect_to manage_questions_admin_assessment_domain_path(@assessment_domain),
                    alert: "Please add at least one question first."
        return
      end

      @stats = {
        total_questions: @questions.count,
        total_options: @questions.sum { |q| q.question_options.count },
        questions_with_options: @questions.count { |q| q.question_options.any? },
        questions_by_type: @questions.group_by(&:response_type).transform_values(&:count)
      }
    end

    def clone
      authorize [ :admin, @assessment_domain ]

      begin
        cloned = @assessment_domain.clone
        redirect_to edit_admin_assessment_domain_path(cloned),
                    notice: "Assessment domain cloned successfully. Update name and version as needed."
      rescue StandardError => e
        redirect_to admin_assessment_domain_path(@assessment_domain),
                    alert: "Failed to clone assessment domain: #{e.message}"
      end
    end

    private

    def set_assessment_domain
      @assessment_domain = AssessmentDomain.find(params[:id])
      # Ensure we're only working with standalone domains
      unless @assessment_domain.standalone?
        redirect_to admin_assessment_domains_path,
                    alert: "This assessment domain is part of an assessment. Manage it through the assessment instead."
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_assessment_domains_path,
                  alert: "Assessment domain not found."
    end

    def set_question
      question_id = params[:question_id] || params[:id]
      @question = Question.find(question_id)
      unless @question.assessment_domain_id == @assessment_domain.id
        raise ActiveRecord::RecordNotFound, "Question not found in this assessment domain"
      end
    end

    def assessment_domain_params
      params.require(:assessment_domain).permit(:name, :version, :description, :profile_domain_id)
    end

    def question_params
      params.require(:question).permit(:code, :text, :response_type, :position)
    end

    def reorder_questions_params
      params.require(:question_positions).permit!
    end
  end
end
