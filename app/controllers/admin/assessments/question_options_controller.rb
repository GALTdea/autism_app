module Admin
  module Assessments
    class QuestionOptionsController < Admin::ApplicationController
      before_action :set_assessment
      before_action :set_assessment_domain
      before_action :set_question
      before_action :set_question_option, only: [:update, :destroy]
      after_action :verify_authorized

      # POST /admin/assessments/:assessment_id/assessment_domains/:section_id/questions/:question_id/question_options
      def create
        authorize [:admin, @assessment], :create_option?

        begin
          @question_option = QuestionOptionService.create_option(@question, question_option_params)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question option created successfully."
            }
            format.json { render json: { status: "success", option: @question_option }, status: :created }
            format.turbo_stream {
              @question.reload
              @assessment_domain.reload
              render :create
            }
          end
        rescue QuestionOptionService::InvalidOptionError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to create option: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
            format.turbo_stream {
              flash.now[:alert] = "Failed to create option: #{e.message}"
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            }
          end
        end
      end

      # PATCH/PUT /admin/assessments/:assessment_id/assessment_domains/:section_id/questions/:question_id/question_options/:option_id
      def update
        authorize [:admin, @assessment], :update_option?

        begin
          QuestionOptionService.update_option(@question_option, question_option_params)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question option updated successfully."
            }
            format.json { render json: { status: "success", option: @question_option.reload } }
            format.turbo_stream {
              @question.reload
              @assessment_domain.reload
              render :update
            }
          end
        rescue QuestionOptionService::UpdateError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to update option: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
            format.turbo_stream {
              flash.now[:alert] = "Failed to update option: #{e.message}"
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            }
          end
        end
      end

      # DELETE /admin/assessments/:assessment_id/assessment_domains/:section_id/questions/:question_id/question_options/:option_id
      def destroy
        authorize [:admin, @assessment], :destroy_option?

        begin
          QuestionOptionService.delete_option(@question_option)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question option deleted successfully."
            }
            format.json { render json: { status: "success", message: "Option deleted successfully." } }
            format.turbo_stream {
              @question.reload
              @assessment_domain.reload
              render :destroy
            }
          end
        rescue QuestionOptionService::DeleteError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to delete option: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
            format.turbo_stream {
              flash.now[:alert] = "Failed to delete option: #{e.message}"
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            }
          end
        end
      end

      # PATCH /admin/assessments/:assessment_id/assessment_domains/:section_id/questions/:question_id/question_options/reorder
      def reorder
        authorize [:admin, @assessment], :reorder_options?

        option_positions = reorder_options_params

        begin
          QuestionOptionService.reorder_options(@question, option_positions)

          @question.reload

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Option order updated successfully."
            }
            format.json { render json: { status: "success", message: "Option order updated successfully." } }
            format.turbo_stream {
              @question.reload
              @assessment_domain.reload
              render :reorder
            }
          end
        rescue QuestionOptionService::UpdateError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to reorder options: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
            format.turbo_stream {
              flash.now[:alert] = "Failed to reorder options: #{e.message}"
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
            }
          end
        end
      end

      private

      def set_assessment
        @assessment = Assessment.find(params[:assessment_id])
      end

      def set_assessment_domain
        @assessment_domain = @assessment.assessment_domains.find(params[:section_id])
      end

      def set_question
        @question = Question.find(params[:question_id])
        unless @question.assessment_domain_id == @assessment_domain.id
          raise ActiveRecord::RecordNotFound, "Question not found in this assessment section"
        end
      end

      def set_question_option
        @question_option = QuestionOption.find(params[:option_id])
        unless @question_option.question_id == @question.id
          raise ActiveRecord::RecordNotFound, "Question option not found in this question"
        end
      end

      def question_option_params
        params.require(:question_option).permit(:label, :value, :position)
      end

      def reorder_options_params
        params.require(:option_positions).permit!
      end
    end
  end
end
