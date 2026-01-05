module Admin
  module Assessments
    class QuestionsController < Admin::ApplicationController
      before_action :set_assessment
      before_action :set_assessment_domain
      before_action :set_question, only: [ :edit_form, :clone ]
      after_action :verify_authorized

      def edit_form
        authorize [ :admin, @assessment ]
        render partial: "admin/assessments/question_form",
               locals: { question: @question, assessment_domain: @assessment_domain, assessment: @assessment }
      end

      def clone
        authorize [ :admin, @assessment ]

        begin
          @question = QuestionCloningService.clone_question(@question, target_domain: @assessment_domain)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question cloned successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @assessment_domain.questions.includes(:question_options).ordered
              render :clone_question
            }
          end
        rescue QuestionCloningService::CloningError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to clone question: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def templates
        authorize [ :admin, @assessment ]
        render partial: "admin/assessments/question_templates",
               locals: { assessment_domain: @assessment_domain, assessment: @assessment }
      end

      def create_from_template
        authorize [ :admin, @assessment ]

        template_key = params[:template_key]
        question_text = params[:question_text]

        begin
          @question = QuestionTemplateService.create_from_template(
            @assessment_domain,
            template_key,
            question_text: question_text
          )

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question created from template successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @assessment_domain.questions.includes(:question_options).ordered
              render :create_from_template
            }
          end
        rescue QuestionTemplateService::Error => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to create question from template: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def copy_from_section_form
        authorize [ :admin, @assessment ]
        @other_sections = @assessment.assessment_domains
                                    .where.not(id: @assessment_domain.id)
                                    .includes(:questions)
                                    .select { |s| s.questions.any? }
        render partial: "admin/assessments/copy_from_section_form",
               locals: { assessment_domain: @assessment_domain, assessment: @assessment, other_sections: @other_sections }
      end

      def copy_from_section
        authorize [ :admin, @assessment ]

        source_question_id = params[:source_question_id]

        begin
          source_question = Question.find(source_question_id)
          @question = QuestionCloningService.copy_question_from_domain(
            source_question,
            @assessment_domain
          )

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          notice: "Question copied from another section successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @assessment_domain.questions.includes(:question_options).ordered
              render :copy_from_section
            }
          end
        rescue ActiveRecord::RecordNotFound
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Source question not found."
            }
            format.json { render json: { status: "error", message: "Source question not found" }, status: :not_found }
          end
        rescue QuestionCloningService::CloningError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                          alert: "Failed to copy question: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def import_csv_form
        authorize [ :admin, @assessment ]
        render partial: "admin/assessments/import_csv_form",
               locals: { assessment_domain: @assessment_domain, assessment: @assessment }
      end

      def import_csv
        authorize [ :admin, @assessment ]

        csv_file = params[:csv_file]

        if csv_file.nil?
          redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                      alert: "Please select a CSV file to import."
          return
        end

        begin
          results = QuestionImportService.import_from_csv(@assessment_domain, csv_file)

          imported_count = results[:imported].count
          error_count = results[:errors].count
          skipped_count = results[:skipped].count

          if error_count > 0 && imported_count == 0
            error_messages = results[:errors].map { |e| "Row #{e[:row]}: #{e[:error]}" }.join("; ")
            redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                        alert: "Import failed: #{error_messages}"
          else
            notice_parts = []
            notice_parts << "#{imported_count} question#{'s' unless imported_count == 1} imported" if imported_count > 0
            notice_parts << "#{skipped_count} skipped" if skipped_count > 0
            notice_parts << "#{error_count} error#{'s' unless error_count == 1}" if error_count > 0

            redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                        notice: notice_parts.join(", ")
          end
        rescue QuestionImportService::InvalidFormatError => e
          redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                      alert: "Invalid CSV format: #{e.message}"
        rescue QuestionImportService::ImportError => e
          redirect_to manage_questions_admin_assessment_assessment_domain_path(@assessment, @assessment_domain),
                      alert: "Import error: #{e.message}"
        end
      end

      def csv_template
        authorize [ :admin, @assessment ]

        respond_to do |format|
          format.csv do
            send_data generate_csv_template,
                      filename: "question_import_template_#{@assessment_domain.profile_domain.key}_#{Date.current.strftime('%Y%m%d')}.csv",
                      type: "text/csv",
                      disposition: "attachment"
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
        question_id = params[:id] || params[:question_id]
        @question = Question.find(question_id)
        if action_name == "edit_form"
          unless @question.assessment_domain_id == @assessment_domain.id
            raise ActiveRecord::RecordNotFound, "Question not found in this assessment section"
          end
        end
      end

      def generate_csv_template
        CSV.generate(headers: true) do |csv|
          headers = [ "code", "text", "response_type", "position" ]
          5.times do |i|
            headers << "option_#{i + 1}_label"
            headers << "option_#{i + 1}_value"
          end
          csv << headers

          csv << [ "COMM_1", "How often does the child initiate communication?", "scale", "0", "Always", "4", "Often", "3", "Sometimes", "2", "Rarely", "1", "Never", "0", "", "" ]
          csv << [ "COMM_2", "Describe the child's communication style", "text", "1", "", "", "", "", "", "", "", "", "", "", "", "" ]
          csv << [ "SOCIAL_1", "Does the child engage in social interactions?", "multi_choice", "2", "Yes", "1", "No", "0", "", "", "", "", "", "", "", "" ]
        end
      end
    end
  end
end
