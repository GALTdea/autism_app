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
          unless @question.profile_domain_id == @profile_domain.id
            raise ActiveRecord::RecordNotFound, "Question not found in this profile domain"
          end
        end
      end
    end
  end
end
