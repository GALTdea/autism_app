class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile
  before_action :set_onboarding_session, only: [:show, :update, :complete]
  after_action :verify_authorized

  def start
    @onboarding_session = OnboardingService.start_session(current_user, @child_profile)
    authorize @onboarding_session

    redirect_to onboarding_child_profile_path(@child_profile)
  end

  def show
    authorize @onboarding_session

    # Get questions organized by domain
    @domains = ProfileDomain.ordered.includes(:questions)
    @current_step = params[:step]&.to_i || 1
    @total_steps = calculate_total_steps

    # Get current domain and questions
    @current_domain = @domains[@current_step - 1]
    @questions = @current_domain&.questions&.ordered || []

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
      
      if turbo_frame_request?
        head :ok
      else
        redirect_to onboarding_child_profile_path(@child_profile, step: params[:current_step])
      end
    rescue OnboardingService::Error => e
      flash[:alert] = e.message
      redirect_to onboarding_child_profile_path(@child_profile, step: params[:current_step])
    end
  end

  def complete
    @onboarding_session = @child_profile.onboarding_sessions
                                        .where(user: current_user, status: 'in_progress')
                                        .first
    
    unless @onboarding_session
      redirect_to start_onboarding_child_profile_path(@child_profile), alert: 'No active onboarding session found.'
      return
    end

    authorize @onboarding_session

    begin
      OnboardingService.complete_session(@onboarding_session)
      redirect_to @child_profile, notice: 'Onboarding completed! Your child\'s profile has been generated.'
    rescue OnboardingService::Error => e
      flash[:alert] = e.message
      redirect_to onboarding_child_profile_path(@child_profile)
    end
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:child_profile_id])
  end

  def set_onboarding_session
    @onboarding_session = @child_profile.onboarding_sessions
                                        .where(user: current_user, status: 'in_progress')
                                        .first

    return if @onboarding_session.present?

    # If no session exists, redirect to start
    redirect_to start_onboarding_child_profile_path(@child_profile), alert: 'Please start the onboarding process.'
  end

  def calculate_total_steps
    ProfileDomain.count
  end
end
