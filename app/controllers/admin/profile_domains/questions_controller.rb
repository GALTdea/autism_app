module Admin
  module ProfileDomains
    class QuestionsController < Admin::ApplicationController
      before_action :set_profile_domain
      before_action :set_question
      after_action :verify_authorized

      def edit_form
        authorize [ :admin, @profile_domain ]
        render partial: "admin/profile_domains/question_form",
               locals: { question: @question, profile_domain: @profile_domain }
      end

      private

      def set_profile_domain
        @profile_domain = ProfileDomain.find(params[:profile_domain_id])
      end

      def set_question
        @question = Question.find(params[:id])
        # Ensure question belongs to the profile domain
        unless @question.profile_domain_id == @profile_domain.id
          raise ActiveRecord::RecordNotFound, "Question not found in this profile domain"
        end
      end
    end
  end
end
