module Admin
  module ProfileDomains
    class QuestionsController < Admin::ApplicationController
      before_action :set_profile_domain
      before_action :set_question, only: [:edit_form, :clone]
      after_action :verify_authorized

      def edit_form
        authorize [ :admin, @profile_domain ]
        render partial: "admin/profile_domains/question_form",
               locals: { question: @question, profile_domain: @profile_domain }
      end

      def clone
        authorize [ :admin, @profile_domain ]

        begin
          @question = QuestionCloningService.clone_question(@question, target_domain: @profile_domain)

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          notice: "Question cloned successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @profile_domain.questions.includes(:question_options).ordered
              render :clone_question
            }
          end
        rescue QuestionCloningService::CloningError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          alert: "Failed to clone question: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def templates
        authorize [ :admin, @profile_domain ]
        render partial: "admin/profile_domains/question_templates",
               locals: { profile_domain: @profile_domain }
      end

      def create_from_template
        authorize [ :admin, @profile_domain ]

        template_key = params[:template_key]
        question_text = params[:question_text]

        begin
          @question = QuestionTemplateService.create_from_template(
            @profile_domain,
            template_key,
            question_text: question_text
          )

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          notice: "Question created from template successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @profile_domain.questions.includes(:question_options).ordered
              render :create_from_template
            }
          end
        rescue QuestionTemplateService::Error => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          alert: "Failed to create question from template: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def copy_from_domain_form
        authorize [ :admin, @profile_domain ]
        @other_domains = ProfileDomain.where.not(id: @profile_domain.id)
                                      .includes(:questions)
                                      .select { |d| d.questions.any? }
        render partial: "admin/profile_domains/copy_from_domain_form",
               locals: { profile_domain: @profile_domain, other_domains: @other_domains }
      end

      def copy_from_domain
        authorize [ :admin, @profile_domain ]

        source_question_id = params[:source_question_id]

        begin
          source_question = Question.find(source_question_id)
          @question = QuestionCloningService.copy_question_from_domain(
            source_question,
            @profile_domain
          )

          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          notice: "Question copied from another domain successfully."
            }
            format.json { render json: { status: "success", question: @question }, status: :created }
            format.turbo_stream {
              @questions = @profile_domain.questions.includes(:question_options).ordered
              render :copy_from_domain
            }
          end
        rescue ActiveRecord::RecordNotFound
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          alert: "Source question not found."
            }
            format.json { render json: { status: "error", message: "Source question not found" }, status: :not_found }
          end
        rescue QuestionCloningService::CloningError => e
          respond_to do |format|
            format.html {
              redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                          alert: "Failed to copy question: #{e.message}"
            }
            format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          end
        end
      end

      def import_csv_form
        authorize [ :admin, @profile_domain ]
        render partial: "admin/profile_domains/import_csv_form",
               locals: { profile_domain: @profile_domain }
      end

      def import_csv
        authorize [ :admin, @profile_domain ]

        csv_file = params[:csv_file]

        if csv_file.nil?
          redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                      alert: "Please select a CSV file to import."
          return
        end

        begin
          results = QuestionImportService.import_from_csv(@profile_domain, csv_file)

          imported_count = results[:imported].count
          error_count = results[:errors].count
          skipped_count = results[:skipped].count

          if error_count > 0 && imported_count == 0
            error_messages = results[:errors].map { |e| "Row #{e[:row]}: #{e[:error]}" }.join("; ")
            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                        alert: "Import failed: #{error_messages}"
          else
            notice_parts = []
            notice_parts << "#{imported_count} question#{'s' unless imported_count == 1} imported" if imported_count > 0
            notice_parts << "#{skipped_count} skipped" if skipped_count > 0
            notice_parts << "#{error_count} error#{'s' unless error_count == 1}" if error_count > 0

            redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                        notice: notice_parts.join(", ")
          end
        rescue QuestionImportService::InvalidFormatError => e
          redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                      alert: "Invalid CSV format: #{e.message}"
        rescue QuestionImportService::ImportError => e
          redirect_to manage_questions_admin_profile_domain_path(@profile_domain),
                      alert: "Import error: #{e.message}"
        end
      end

      def csv_template
        authorize [ :admin, @profile_domain ]

        respond_to do |format|
          format.csv do
            send_data generate_csv_template,
                      filename: "question_import_template_#{@profile_domain.key}_#{Date.current.strftime('%Y%m%d')}.csv",
                      type: 'text/csv',
                      disposition: 'attachment'
          end
        end
      end

      private

      def generate_csv_template
        CSV.generate(headers: true) do |csv|
          # Header row
          headers = ['code', 'text', 'response_type', 'position']
          # Add option columns (example with 5 options)
          5.times do |i|
            headers << "option_#{i + 1}_label"
            headers << "option_#{i + 1}_value"
          end
          csv << headers

          # Example rows
          csv << ['COMM_1', 'How often does the child initiate communication?', 'scale', '0', 'Always', '4', 'Often', '3', 'Sometimes', '2', 'Rarely', '1', 'Never', '0', '', '']
          csv << ['COMM_2', 'Describe the child\'s communication style', 'text', '1', '', '', '', '', '', '', '', '', '', '', '', '']
          csv << ['SOCIAL_1', 'Does the child engage in social interactions?', 'multi_choice', '2', 'Yes', '1', 'No', '0', '', '', '', '', '', '', '', '']
        end
      end

      private

      def set_profile_domain
        @profile_domain = ProfileDomain.find(params[:profile_domain_id])
      end

      def set_question
        question_id = params[:id] || params[:question_id]
        @question = Question.find(question_id)
        # For clone, question doesn't need to belong to this domain
        # For edit_form, we check below
        if action_name == 'edit_form'
          unless @question.assessment_domain&.profile_domain_id == @profile_domain.id
            raise ActiveRecord::RecordNotFound, "Question not found in this profile domain"
          end
        end
      end
    end
  end
end
