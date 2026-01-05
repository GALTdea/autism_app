module Admin
  module Assessments
    class AssessmentDomainsController < Admin::ApplicationController
      before_action :set_assessment
      before_action :set_assessment_domain, only: [
        :manage_questions, :create_question, :update_question,
        :destroy_question, :reorder_questions, :preview_questions
      ]
      before_action :set_question, only: [ :update_question, :destroy_question ]
      after_action :verify_authorized

      def manage_questions
        authorize [ :admin, @assessment ]
        @questions = @assessment_domain.questions.includes(:question_options).ordered
        @assessment_sections = @assessment.assessment_domains.includes(:profile_domain).ordered
      end

      def create_question
        authorize [ :admin, @assessment ]

        begin
          @question = QuestionManagementService.create_question(@assessment_domain, question_params)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
        authorize [ :admin, @assessment ]

        begin
          QuestionManagementService.update_question(@question, question_params)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
        authorize [ :admin, @assessment ]

        begin
          QuestionManagementService.delete_question(@question)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
        authorize [ :admin, @assessment ]

        question_positions = reorder_questions_params

        begin
          QuestionManagementService.reorder_questions(@assessment_domain, question_positions)

          @assessment_domain.reload
          @questions = @assessment_domain.questions.includes(:question_options).ordered

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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

      def preview_questions
        authorize [ :admin, @assessment ]
        @questions = @assessment_domain.questions.includes(:question_options).ordered

        if @questions.empty?
          redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
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

      private

      def set_assessment
        @assessment = Assessment.find(params[:assessment_id])
      end

      def set_assessment_domain
        @assessment_domain = @assessment.assessment_domains.find(params[:section_id] || params[:id])
      end

      def set_question
        question_id = params[:question_id] || params[:id]
        @question = Question.find(question_id)
        unless @question.assessment_domain_id == @assessment_domain.id
          raise ActiveRecord::RecordNotFound, "Question not found in this assessment section"
        end
      end

      def question_params
        params.require(:question).permit(:code, :text, :response_type, :position)
      end

      def reorder_questions_params
        params.require(:question_positions).permit!
      end
    end
  end
end
