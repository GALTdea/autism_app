class OnboardingService
  class Error < StandardError; end
  class SessionNotFoundError < Error; end
  class QuestionNotFoundError < Error; end
  class InvalidAnswerError < Error; end

  def self.start_session(user, child_profile)
    new(user, child_profile).start_session
  end

  def self.save_answer(session, question_id, answer_data)
    new(nil, nil, session).save_answer(question_id, answer_data)
  end

  def self.complete_session(session)
    new(nil, nil, session).complete_session
  end

  def initialize(user = nil, child_profile = nil, session = nil)
    @user = user
    @child_profile = child_profile
    @session = session
  end

  def start_session
    raise Error, 'User and child_profile are required' if @user.nil? || @child_profile.nil?

    # Check if there's an existing in-progress session
    existing_session = OnboardingSession.find_by(
      child_profile: @child_profile,
      user: @user,
      status: 'in_progress'
    )

    return existing_session if existing_session.present?

    OnboardingSession.create!(
      child_profile: @child_profile,
      user: @user,
      status: 'in_progress'
    )
  end

  def save_answer(question_id, answer_data)
    raise SessionNotFoundError, 'Session not found' if @session.nil?
    raise Error, 'Session is already completed' if @session.completed?

    question = Question.find_by(id: question_id)
    raise QuestionNotFoundError, "Question #{question_id} not found" if question.nil?

    # Extract answer data
    question_option_id = answer_data[:question_option_id]
    numeric_value = answer_data[:numeric_value]
    free_text = answer_data[:free_text]

    # Set numeric_value from question_option if provided
    if question_option_id.present?
      question_option = QuestionOption.find_by(id: question_option_id)
      raise InvalidAnswerError, 'Invalid question option' if question_option.nil? || question_option.question_id != question.id
      numeric_value ||= question_option.value
    end

    # Find or create answer
    answer = Answer.find_or_initialize_by(
      onboarding_session: @session,
      question: question
    )

    answer.assign_attributes(
      question_option_id: question_option_id,
      numeric_value: numeric_value,
      free_text: free_text
    )

    if answer.save
      answer
    else
      raise InvalidAnswerError, answer.errors.full_messages.join(', ')
    end
  end

  def complete_session
    raise SessionNotFoundError, 'Session not found' if @session.nil?
    raise Error, 'Session is already completed' if @session.completed?

    @session.update!(status: 'completed')

    # Trigger profile generation
    ProfileGenerationService.generate_profile(@session.child_profile, @session)

    @session
  end
end

