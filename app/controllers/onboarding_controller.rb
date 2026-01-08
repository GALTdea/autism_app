class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile
  before_action :set_onboarding_session, only: [ :show, :update, :complete ]
  after_action :verify_authorized

  def start
    @onboarding_session = OnboardingService.start_session(current_user, @child_profile)
    authorize @onboarding_session

    redirect_to onboarding_child_profile_path(@child_profile)
  end

  def show
    authorize @onboarding_session

    # Get assessment_sections from the assessment
    assessment = @onboarding_session.assessment || Assessment.default.first || Assessment.active.first

    if assessment
      # Get assessment_domains (sections) with their questions
      @assessment_sections = assessment.assessment_domains.includes(:questions, :profile_domain).ordered
      @domains = assessment.ordered_domains  # For backward compatibility in views
    else
      # Fallback (should not happen in practice)
      @assessment_sections = AssessmentDomain.none
      @domains = ProfileDomain.ordered
    end

    @current_step = params[:step]&.to_i || 1
    @total_steps = calculate_total_steps

    # Get current section and questions
    @current_section = @assessment_sections[@current_step - 1]
    @current_domain = @current_section&.profile_domain  # For backward compatibility
    @questions = @current_section&.questions&.ordered || []

    # If no current section found, redirect to start or show error
    unless @current_section.present?
      flash[:alert] = "Invalid step. Please start the onboarding process again."
      redirect_to start_onboarding_child_profile_path(@child_profile) and return
    end

    # Load existing answers for current questions
    @answers = {}
    @questions.each do |question|
      answer = @onboarding_session.answers.find_by(question: question)
      @answers[question.id] = answer if answer
    end
  end

  def update
    authorize @onboarding_session

    question_id = params[:question_id]
    answer_data = {
      question_option_id: params[:question_option_id].presence,
      numeric_value: params[:numeric_value].presence&.to_i,
      free_text: params[:free_text].presence
    }

    begin
      OnboardingService.save_answer(@onboarding_session, question_id, answer_data)

      # Handle AJAX/fetch requests (from Stimulus)
      if request.xhr? || request.headers["X-Requested-With"] == "XMLHttpRequest"
        render json: { status: "ok" }, status: :ok
      elsif turbo_frame_request?
        head :ok
      else
        # Regular form submission - redirect
        redirect_to onboarding_child_profile_path(@child_profile, step: params[:current_step] || params[:step])
      end
    rescue OnboardingService::Error => e
      # Handle errors for AJAX requests
      if request.xhr? || request.headers["X-Requested-With"] == "XMLHttpRequest"
        render json: { error: e.message }, status: :unprocessable_entity
      else
        flash[:alert] = e.message
        redirect_to onboarding_child_profile_path(@child_profile, step: params[:current_step] || params[:step])
      end
    end
  end

  def complete
    @onboarding_session = @child_profile.onboarding_sessions
                                        .where(user: current_user, status: "in_progress")
                                        .first

    unless @onboarding_session
      redirect_to start_onboarding_child_profile_path(@child_profile), alert: "No active onboarding session found."
      return
    end

    authorize @onboarding_session

    begin
      OnboardingService.complete_session(@onboarding_session)
      redirect_to @child_profile, notice: "Onboarding completed! Your child's profile has been generated."
    rescue OnboardingService::Error => e
      flash[:alert] = e.message
      redirect_to onboarding_child_profile_path(@child_profile)
    end
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:id])
  end

  def set_onboarding_session
    @onboarding_session = @child_profile.onboarding_sessions
                                        .where(user: current_user, status: "in_progress")
                                        .first

    return if @onboarding_session.present?

    # If no session exists, redirect to start
    redirect_to start_onboarding_child_profile_path(@child_profile), alert: "Please start the onboarding process."
  end

  def calculate_total_steps
    # Use assessment domains if available, otherwise count all domains
    assessment = @onboarding_session&.assessment || Assessment.default.first || Assessment.active.first
    assessment ? assessment.domain_count : ProfileDomain.count
  end
end
