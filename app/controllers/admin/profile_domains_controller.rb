module Admin
  class ProfileDomainsController < Admin::ApplicationController
    before_action :set_profile_domain, only: [ :show, :edit, :update, :destroy,
                                                :manage_questions, :create_question,
                                                :update_question, :destroy_question,
                                                :reorder_questions, :preview ]
    before_action :set_question, only: [ :update_question, :destroy_question ]
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

      if @profile_domain.can_be_deleted?
        @profile_domain.destroy
        redirect_to admin_profile_domains_path,
                    notice: "Profile domain deleted successfully."
      else
        blockers = @profile_domain.deletion_blockers.join(", ")
        redirect_to admin_profile_domains_path,
                    alert: "Cannot delete profile domain. #{blockers}"
      end
    end

    # Question Management Actions

    def manage_questions
      authorize [ :admin, @profile_domain ]
      @questions = @profile_domain.questions.includes(:question_options).ordered
    end

    def create_question
      authorize [ :admin, @profile_domain ]

      begin
        @question = QuestionManagementService.create_question(@profile_domain, question_params)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                        notice: "Question created successfully."
          }
          format.json { render json: { status: "success", question: @question }, status: :created }
          format.turbo_stream {
            @questions = @profile_domain.questions.includes(:question_options).ordered
            render :create_question
          }
        end
      rescue QuestionManagementService::InvalidQuestionError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
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
      authorize [ :admin, @profile_domain ]

      begin
        QuestionManagementService.update_question(@question, question_params)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                        notice: "Question updated successfully."
          }
          format.json { render json: { status: "success", question: @question.reload } }
          format.turbo_stream {
            @questions = @profile_domain.questions.includes(:question_options).ordered
            render :update_question
          }
        end
      rescue QuestionManagementService::UpdateError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
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
      authorize [ :admin, @profile_domain ]

      begin
        QuestionManagementService.delete_question(@question)

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                        notice: "Question deleted successfully."
          }
          format.json { render json: { status: "success", message: "Question deleted successfully." } }
          format.turbo_stream {
            @questions = @profile_domain.questions.includes(:question_options).ordered
            render :destroy_question
          }
        end
      rescue QuestionManagementService::DeleteError => e
        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
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
      authorize [ :admin, @profile_domain ]

      question_positions = reorder_questions_params

      begin
        QuestionManagementService.reorder_questions(@profile_domain, question_positions)

        # Reload to get updated positions
        @profile_domain.reload
        @questions = @profile_domain.questions.includes(:question_options).ordered

        respond_to do |format|
          format.html {
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
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
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
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
      authorize [ :admin, @profile_domain ]
      @questions = @profile_domain.questions.includes(:question_options).ordered

      if @questions.empty?
        redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                    alert: "Please add at least one question first."
        return
      end

      # Calculate statistics
      @stats = {
        total_questions: @questions.count,
        total_options: @questions.sum { |q| q.question_options.count },
        questions_with_options: @questions.count { |q| q.question_options.any? },
        questions_by_type: @questions.group_by(&:response_type).transform_values(&:count)
      }
    end

    private

    def set_profile_domain
      @profile_domain = ProfileDomain.find(params[:id])
    end

    def set_question
      question_id = params[:question_id] || params[:id]
      @question = Question.find(question_id)
      # Ensure question belongs to the profile domain
      unless @question.profile_domain_id == @profile_domain.id
        raise ActiveRecord::RecordNotFound, "Question not found in this profile domain"
      end
    end

    def profile_domain_params
      params.require(:profile_domain).permit(:key, :label, :description)
    end

    def question_params
      params.require(:question).permit(:code, :text, :response_type, :position)
    end

    def reorder_questions_params
      params.require(:question_positions).permit! # Permit all for now, will refine if needed
    end
  end
end
