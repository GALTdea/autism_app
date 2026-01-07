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
    # Convert ActionController::Parameters to a regular hash to avoid permission issues
    # This handles nested parameters (like question_options_attributes) properly
    if params.is_a?(ActionController::Parameters)
      params = params.to_unsafe_h.deep_stringify_keys
    else
      params = params.stringify_keys
    end

    ActiveRecord::Base.transaction do
      # Auto-generate code if not provided or if blank
      if params['code'].blank?
        params['code'] = generate_question_code
      end

      # Auto-assign position if not provided or blank (empty string)
      params['position'] = next_position if params['position'].blank?

      # Ensure assessment_domain is set
      params['assessment_domain_id'] = @assessment_domain.id

      # Ensure domain field matches domain key (handles both profile_domain and name-based keys)
      params['domain'] = @assessment_domain.domain_key

      # Set positions for question options if not provided, and ensure they're integers
      if params['question_options_attributes'].present?
        params['question_options_attributes'].each_with_index do |(key, option_attrs), index|
          # Option attrs should already be a hash after deep_stringify_keys
          option_hash = option_attrs.is_a?(Hash) ? option_attrs : option_attrs.to_h

          # Set position and convert value to integer
          option_hash['position'] = (option_hash['position'] || index).to_i
          option_hash['value'] = option_hash['value'].to_i if option_hash['value'].present?

          # Update the params
          params['question_options_attributes'][key] = option_hash
        end
      end

      question = Question.new(params)

      Rails.logger.info "About to validate question. Params keys: #{params.keys.inspect}"
      Rails.logger.info "Question options attributes present: #{params['question_options_attributes'].present?}"
      Rails.logger.info "Question options count: #{params['question_options_attributes']&.count}"

      # Validate and log errors before attempting save
      is_valid = question.valid?
      Rails.logger.info "Question valid?: #{is_valid}"

      unless is_valid
        error_details = []
        error_details << "Question: #{question.errors.full_messages.join(', ')}"
        question.question_options.each_with_index do |opt, i|
          opt_valid = opt.valid?
          Rails.logger.info "Option #{i+1} valid?: #{opt_valid}, errors: #{opt.errors.full_messages}"
          if opt.errors.any? || !opt_valid
            error_details << "Option #{i+1}: #{opt.errors.full_messages.join(', ')}"
          end
        end
        error_msg = error_details.join(' | ')
        Rails.logger.error "Validation failed: #{error_msg}"
        raise InvalidQuestionError, "Validation failed: #{error_msg}"
      end

      Rails.logger.info "Validation passed, attempting save..."
      question.save!
      Rails.logger.info "Save successful! Question ID: #{question.id}"

      # Normalize question option positions after save (ensure they're sequential)
      if question.question_options.any?
        question.question_options.ordered.each_with_index do |option, index|
          option.update_column(:position, index) if option.position != index
        end
      end

      question
    rescue ActiveRecord::RecordInvalid => e
      error_messages = []
      error_messages << "Question errors: #{e.record.errors.full_messages.join(", ")}"
      if e.record.question_options.any?
        e.record.question_options.each_with_index do |option, index|
          if option.errors.any?
            error_messages << "Option #{index + 1} errors: #{option.errors.full_messages.join(", ")}"
          end
        end
      end
      error_msg = "Failed to create question: #{error_messages.join("; ")}"
      Rails.logger.error "Question creation failed (RecordInvalid): #{error_msg}"
      Rails.logger.error "Exception: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise InvalidQuestionError, error_msg
    rescue StandardError => e
      error_msg = "Unexpected error creating question: #{e.class} - #{e.message}"
      Rails.logger.error error_msg
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise InvalidQuestionError, error_msg
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

      # Normalize question option positions if options were updated
      if question.question_options.any?
        question.question_options.ordered.each_with_index do |option, index|
          option.update_column(:position, index) if option.position != index
        end
      end

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
