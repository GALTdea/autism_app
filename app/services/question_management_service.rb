class QuestionManagementService
  class Error < StandardError; end
  class InvalidQuestionError < Error; end
  class UpdateError < Error; end
  class DeleteError < Error; end

  def self.create_question(assessment_domain, params)
    new(assessment_domain).create_question(params)
  end

  def self.update_question(question, params)
    new(question.assessment_domain).update_question(question, params)
  end

  def self.reorder_questions(assessment_domain, positions)
    new(assessment_domain).reorder_questions(positions)
  end

  def self.delete_question(question)
    new(question.assessment_domain).delete_question(question)
  end

  def initialize(assessment_domain)
    @assessment_domain = assessment_domain
    raise Error, "Assessment domain is required" if @assessment_domain.nil?
  end

  def create_question(params)
    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Auto-generate code if not provided
      params['code'] ||= generate_question_code

      # Auto-assign position if not provided
      params['position'] ||= next_position

      # Ensure assessment_domain is set
      params['assessment_domain_id'] = @assessment_domain.id

      # Ensure domain field matches domain key (handles both profile_domain and name-based keys)
      params['domain'] = @assessment_domain.domain_key

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
    raise InvalidQuestionError, "Question does not belong to this assessment domain" unless question.assessment_domain_id == @assessment_domain.id

    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Don't allow changing assessment_domain_id
      params.delete('assessment_domain_id')
      params.delete('assessment_domain')

      # Ensure domain field stays in sync (handles both profile_domain and name-based keys)
      if params.key?('domain') || question.domain != @assessment_domain.domain_key
        params['domain'] = @assessment_domain.domain_key
      end

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
        question = @assessment_domain.questions.find_by(id: question_id)
        next unless question

        new_position = position.to_i
        question.update!(position: new_position)
      end

      # Renormalize positions to ensure they're sequential starting from 0
      normalize_positions

      @assessment_domain
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to reorder questions: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error during reordering: #{e.message}"
    end
  end

  def delete_question(question)
    raise InvalidQuestionError, "Question does not belong to this assessment domain" unless question.assessment_domain_id == @assessment_domain.id
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

    # Normalize domain key to valid code format (uppercase, only alphanumeric and underscores)
    # Use domain_key method which handles both profile_domain and name-based keys
    domain_key = @assessment_domain.domain_key
    raise InvalidQuestionError, "Assessment domain must have a profile_domain or name for code generation" if domain_key.blank?

    domain_prefix = normalize_domain_key(domain_key)
    raise InvalidQuestionError, "Invalid domain key for code generation" if domain_prefix.blank?

    # Get the highest number for questions with this domain prefix in this assessment_domain
    existing_codes = @assessment_domain.questions.pluck(:code)
    max_number = existing_codes
                  .select { |code| code&.match?(/^#{Regexp.escape(domain_prefix)}_\d+$/) }
                  .map { |code| code.split('_').last.to_i }
                  .max || 0

    # Generate new code with next sequential number
    new_number = max_number + 1
    new_code = "#{domain_prefix}_#{new_number}"

    # Ensure uniqueness within this assessment_domain (code is unique per assessment_domain)
    counter = new_number
    max_attempts = 1000 # Safety limit to prevent infinite loops
    attempts = 0

    while @assessment_domain.questions.exists?(code: new_code)
      counter += 1
      new_code = "#{domain_prefix}_#{counter}"
      attempts += 1

      if attempts >= max_attempts
        raise InvalidQuestionError, "Unable to generate unique question code after #{max_attempts} attempts"
      end
    end

    new_code
  end

  def normalize_domain_key(key)
    # Convert domain key to valid code format:
    # - Uppercase
    # - Replace spaces and hyphens with underscores
    # - Remove invalid characters (keep only alphanumeric and underscores)
    return nil if key.blank?

    normalized = key.to_s.upcase
                   .gsub(/[^A-Z0-9_]+/, '_')  # Replace invalid chars with underscore
                   .gsub(/_+/, '_')           # Collapse multiple underscores
                   .gsub(/^_|_$/, '')         # Remove leading/trailing underscores

    # Ensure it's not empty and starts with a letter or number
    normalized.present? && normalized.match?(/^[A-Z0-9]/) ? normalized : nil
  end

  def next_position
    # Get the maximum position for questions in this assessment_domain, add 1
    max_position = @assessment_domain.questions.maximum(:position)
    (max_position || -1) + 1
  end

  def normalize_positions
    # Ensure positions are sequential starting from 0
    @assessment_domain.questions.ordered.each_with_index do |question, index|
      question.update_column(:position, index)
    end
  end
end
