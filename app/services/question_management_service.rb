class QuestionManagementService
  class Error < StandardError; end
  class InvalidQuestionError < Error; end
  class UpdateError < Error; end
  class DeleteError < Error; end

  def self.create_question(profile_domain, params)
    new(profile_domain).create_question(params)
  end

  def self.update_question(question, params)
    new(question.profile_domain).update_question(question, params)
  end

  def self.reorder_questions(profile_domain, positions)
    new(profile_domain).reorder_questions(positions)
  end

  def self.delete_question(question)
    new(question.profile_domain).delete_question(question)
  end

  def initialize(profile_domain)
    @profile_domain = profile_domain
    raise Error, "Profile domain is required" if @profile_domain.nil?
  end

  def create_question(params)
    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Auto-generate code if not provided
      params['code'] ||= generate_question_code

      # Auto-assign position if not provided
      params['position'] ||= next_position

      # Ensure profile_domain is set
      params['profile_domain_id'] = @profile_domain.id

      # Ensure domain field matches profile_domain key (for backwards compatibility)
      params['domain'] = @profile_domain.key

      question = Question.new(params)
      question.save!

      question
    rescue ActiveRecord::RecordInvalid => e
      raise InvalidQuestionError, "Failed to create question: #{e.message}"
    rescue StandardError => e
      raise InvalidQuestionError, "Unexpected error creating question: #{e.message}"
    end
  end

  def update_question(question, params)
    raise InvalidQuestionError, "Question does not belong to this domain" unless question.profile_domain_id == @profile_domain.id

    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Don't allow changing profile_domain_id
      params.delete('profile_domain_id')
      params.delete('profile_domain')

      # Ensure domain field stays in sync
      params['domain'] = @profile_domain.key if params.key?('domain') || question.domain != @profile_domain.key

      question.update!(params)

      question
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to update question: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error updating question: #{e.message}"
    end
  end

  def reorder_questions(positions)
    # positions should be a hash: { question_id => position }
    positions = positions.stringify_keys

    ActiveRecord::Base.transaction do
      positions.each do |question_id, position|
        question = @profile_domain.questions.find_by(id: question_id)
        next unless question

        new_position = position.to_i
        question.update!(position: new_position)
      end

      # Renormalize positions to ensure they're sequential starting from 0
      normalize_positions

      @profile_domain
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to reorder questions: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error during reordering: #{e.message}"
    end
  end

  def delete_question(question)
    raise InvalidQuestionError, "Question does not belong to this domain" unless question.profile_domain_id == @profile_domain.id
    raise DeleteError, "Cannot delete question that has answers" if question.answers.any?

    ActiveRecord::Base.transaction do
      question.destroy!
      # Renormalize positions after deletion
      normalize_positions
      question
    rescue ActiveRecord::RecordInvalid => e
      raise DeleteError, "Failed to delete question: #{e.message}"
    rescue StandardError => e
      raise DeleteError, "Unexpected error deleting question: #{e.message}"
    end
  end

  private

  def generate_question_code
    # Generate code based on domain key and next number
    # Format: {DOMAIN_KEY}_{NUMBER}
    # Example: COMM_1, COMM_2, SOCIAL_1, etc.
    domain_prefix = @profile_domain.key.upcase

    # Get the highest number for this domain
    existing_codes = @profile_domain.questions.pluck(:code)
    max_number = existing_codes
                  .select { |code| code&.match?(/^#{domain_prefix}_\d+$/) }
                  .map { |code| code.split('_').last.to_i }
                  .max || 0

    new_number = max_number + 1
    new_code = "#{domain_prefix}_#{new_number}"

    # Ensure uniqueness (in case there are questions with non-standard codes)
    counter = new_number
    while Question.exists?(code: new_code)
      counter += 1
      new_code = "#{domain_prefix}_#{counter}"
    end

    new_code
  end

  def next_position
    # Get the maximum position for questions in this domain, add 1
    max_position = @profile_domain.questions.maximum(:position)
    (max_position || -1) + 1
  end

  def normalize_positions
    # Ensure positions are sequential starting from 0
    @profile_domain.questions.ordered.each_with_index do |question, index|
      question.update_column(:position, index)
    end
  end
end
