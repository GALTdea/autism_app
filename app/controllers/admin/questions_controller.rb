module Admin
  class QuestionsController < Admin::ApplicationController
    after_action :verify_authorized

    def index
      authorize [ :admin, Question ]
      @questions = policy_scope([ :admin, Question ])
        .joins(assessment_domain: :profile_domain)
        .includes(assessment_domain: :profile_domain, question_options: [])
        .order("profile_domains.label, questions.position")
    end
  end
end
