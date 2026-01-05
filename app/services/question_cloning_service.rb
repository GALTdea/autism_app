class QuestionCloningService
  class Error < StandardError; end
  class CloningError < Error; end

  def self.clone_question(question, target_domain: nil, code: nil)
    target_domain ||= question.assessment_domain
    new(question, target_domain).clone_question(code: code)
  end

  def self.copy_question_from_domain(source_question, target_domain, code: nil)
    new(source_question, target_domain).clone_question(code: code)
  end

  def initialize(question, target_domain)
    @question = question
    @target_domain = target_domain
    raise Error, "Question is required" if @question.nil?
    raise Error, "Target domain is required" if @target_domain.nil?
  end

  def clone_question(code: nil)
    ActiveRecord::Base.transaction do
      # Generate new code if not provided
      new_code = code || generate_clone_code

      # Get next position in target domain (manually calculate)
      max_position = @target_domain.questions.maximum(:position)
      new_position = (max_position || -1) + 1

      # Determine domain key (works with both AssessmentDomain and ProfileDomain for backward compatibility)
      domain_key = @target_domain.respond_to?(:profile_domain) ? @target_domain.profile_domain.key : @target_domain.key

      # Create cloned question
      cloned_question = Question.create!(
        code: new_code,
        text: @question.text,
        response_type: @question.response_type,
        position: new_position,
        assessment_domain_id: @target_domain.id,
        domain: domain_key
      )

      # Clone question options if they exist
      if @question.question_options.any?
        @question.question_options.ordered.each do |option|
          cloned_question.question_options.create!(
            label: option.label,
            value: option.value,
            position: option.position
          )
        end
      end

      cloned_question.reload
    rescue ActiveRecord::RecordInvalid => e
      raise CloningError, "Failed to clone question: #{e.message}"
    rescue StandardError => e
      raise CloningError, "Unexpected error during cloning: #{e.message}"
    end
  end

  private

  def generate_clone_code
    # Normalize domain key (works with both AssessmentDomain and ProfileDomain)
    domain_key = @target_domain.respond_to?(:profile_domain) ? @target_domain.profile_domain.key : @target_domain.key
    domain_prefix = normalize_domain_key(domain_key)
    raise CloningError, "Invalid domain key for code generation" if domain_prefix.blank?

    # Extract number from original code
    original_number = @question.code.split('_').last

    # Try appending _COPY
    new_code = "#{domain_prefix}_#{original_number}_COPY"

    # If code already exists in this assessment_domain, add a number
    if @target_domain.questions.exists?(code: new_code)
      counter = 2
      loop do
        new_code = "#{domain_prefix}_#{original_number}_COPY#{counter}"
        break unless @target_domain.questions.exists?(code: new_code)
        counter += 1
        raise CloningError, "Too many clones with same code pattern" if counter > 100
      end
    end

    new_code
  end

  def normalize_domain_key(key)
    # Convert domain key to valid code format (same logic as QuestionManagementService)
    return nil if key.blank?

    normalized = key.to_s.upcase
                   .gsub(/[^A-Z0-9_]+/, '_')
                   .gsub(/_+/, '_')
                   .gsub(/^_|_$/, '')

    normalized.present? && normalized.match?(/^[A-Z0-9]/) ? normalized : nil
  end
end
