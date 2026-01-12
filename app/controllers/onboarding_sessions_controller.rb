class OnboardingSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile
  before_action :set_onboarding_session
  after_action :verify_authorized

  def show
    authorize @onboarding_session

    # Load assessment with all domains and questions
    @assessment = @onboarding_session.assessment

    # Load answers with questions, assessment domains, and options
    @answers = @onboarding_session.answers
      .includes(
        question: [
          :assessment_domain,
          { question_options: [] }
        ],
        question_option: []
      )
      .order('questions.position')

    # Preload assessment domains if assessment exists
    if @assessment.present?
      @assessment.assessment_domains.includes(:profile_domain).load
    end

    # Group answers by assessment domain
    @answers_by_domain = {}
    if @assessment.present?
      @assessment.ordered_assessment_domains.each do |assessment_domain|
        domain_answers = @answers.select { |a| a.question.assessment_domain_id == assessment_domain.id }
        @answers_by_domain[assessment_domain] = domain_answers if domain_answers.any?
      end
    else
      # Fallback: group by question's assessment domain
      @answers.group_by { |a| a.question.assessment_domain }.each do |domain, answers|
        @answers_by_domain[domain] = answers if domain.present?
      end
    end
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:child_profile_id])
  end

  def set_onboarding_session
    @onboarding_session = @child_profile.onboarding_sessions.find(params[:session_id])
  end
end
