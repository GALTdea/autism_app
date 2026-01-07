module Admin
  module AssessmentDomains
    class QuestionsController < Admin::ApplicationController
      before_action :set_assessment_domain
      before_action :set_question, only: [:edit]
      after_action :verify_authorized

      def new
        authorize [ :admin, @assessment_domain ]
        @question = Question.new(assessment_domain: @assessment_domain)
        render partial: "admin/assessment_domains/question_form",
               locals: { assessment_domain: @assessment_domain, question: @question },
               layout: false
      end

      def edit
        authorize [ :admin, @assessment_domain ]
        render partial: "admin/assessment_domains/question_form",
               locals: { assessment_domain: @assessment_domain, question: @question },
               layout: false
      end

      private

      def set_assessment_domain
        @assessment_domain = AssessmentDomain.find(params[:assessment_domain_id])
        unless @assessment_domain.standalone?
          redirect_to admin_assessment_domains_path,
                      alert: "This assessment domain is part of an assessment. Manage it through the assessment instead."
        end
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_assessment_domains_path,
                    alert: "Assessment domain not found."
      end

      def set_question
        @question = Question.find(params[:id])
        unless @question.assessment_domain_id == @assessment_domain.id
          raise ActiveRecord::RecordNotFound, "Question not found in this assessment domain"
        end
      end
    end
  end
end
