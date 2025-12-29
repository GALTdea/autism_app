class QuestionBulkImportService
  class Error < StandardError; end
  class ImportError < Error; end
  class InvalidFormatError < Error; end

  def self.import_from_json(json_data)
    new.import_from_json(json_data)
  end

  def self.import_from_file(file_path)
    json_content = File.read(file_path)
    json_data = JSON.parse(json_content)
    new.import_from_json(json_data)
  end

  def initialize
    @errors = []
    @warnings = []
    @imported_questions = []
    @created_domains = []
    @updated_questions = []
  end

  def import_from_json(json_data)
    raise InvalidFormatError, "JSON data is required" if json_data.nil?

    results = {
      domains_created: [],
      questions_imported: [],
      questions_updated: [],
      errors: [],
      warnings: []
    }

    ActiveRecord::Base.transaction do
      # Handle single domain format: { domain: {...}, questions: [...] }
      if json_data['domain'] && json_data['questions']
        domain_result = import_domain_with_questions(json_data['domain'], json_data['questions'])
        results[:domains_created] << domain_result[:domain] if domain_result[:domain_created]
        results[:questions_imported].concat(domain_result[:imported])
        results[:questions_updated].concat(domain_result[:updated])
        results[:errors].concat(domain_result[:errors])
        results[:warnings].concat(domain_result[:warnings])

      # Handle multi-domain format: { domains: [{ domain: {...}, questions: [...] }, ...] }
      elsif json_data['domains']
        json_data['domains'].each do |domain_data|
          domain_result = import_domain_with_questions(domain_data['domain'], domain_data['questions'])
          results[:domains_created] << domain_result[:domain] if domain_result[:domain_created]
          results[:questions_imported].concat(domain_result[:imported])
          results[:questions_updated].concat(domain_result[:updated])
          results[:errors].concat(domain_result[:errors])
          results[:warnings].concat(domain_result[:warnings])
        end
      else
        raise InvalidFormatError, "Invalid JSON format. Expected 'domain' and 'questions', or 'domains' array"
      end

      # Raise error if there were critical errors
      if results[:errors].any? && results[:questions_imported].empty?
        raise ImportError, "Import failed: #{results[:errors].first[:error]}"
      end

      results
    rescue ActiveRecord::RecordInvalid => e
      raise ImportError, "Validation error: #{e.message}"
    rescue StandardError => e
      raise ImportError, "Unexpected error during import: #{e.message}"
    end
  end

  private

  def import_domain_with_questions(domain_data, questions_data)
    result = {
      domain: nil,
      domain_created: false,
      imported: [],
      updated: [],
      errors: [],
      warnings: []
    }

    # Validate domain data
    domain_key = domain_data&.dig('key')&.strip
    raise InvalidFormatError, "Domain key is required" if domain_key.blank?

    # Create or find domain
    domain = ProfileDomain.find_by(key: domain_key)
    domain_created = false

    if domain.nil?
      domain_label = domain_data['label']&.strip || domain_key.humanize
      domain_description = domain_data['description']&.strip

      domain = ProfileDomain.create!(
        key: domain_key,
        label: domain_label,
        description: domain_description
      )
      domain_created = true
      @created_domains << domain
      result[:warnings] << { domain: domain_key, message: "Created new domain: #{domain_label}" }
    else
      # Update domain metadata if provided (optional updates)
      if domain_data['label']&.strip.present? && domain.label != domain_data['label'].strip
        domain.update(label: domain_data['label'].strip)
        result[:warnings] << { domain: domain_key, message: "Updated domain label" }
      end
      if domain_data['description']&.strip.present? && domain.description != domain_data['description'].strip
        domain.update(description: domain_data['description'].strip)
      end
    end

    result[:domain] = domain
    result[:domain_created] = domain_created

    # Import questions
    return result if questions_data.blank? || !questions_data.is_a?(Array)

    questions_data.each_with_index do |question_data, index|
      begin
        question_result = import_question(domain, question_data, index + 1)
        if question_result[:imported]
          result[:imported] << question_result[:question]
        elsif question_result[:updated]
          result[:updated] << question_result[:question]
        end
        result[:warnings].concat(question_result[:warnings]) if question_result[:warnings].any?
      rescue => e
        result[:errors] << {
          question_index: index + 1,
          error: e.message
        }
        @errors << "Question #{index + 1}: #{e.message}"
      end
    end

    result
  end

  def import_question(domain, question_data, question_number)
    result = {
      question: nil,
      imported: false,
      updated: false,
      warnings: []
    }

    # Validate required fields
    code = question_data['code']&.strip
    text = question_data['text']&.strip
    response_type = question_data['response_type']&.strip&.downcase

    raise ImportError, "Question code is required" if code.blank?
    raise ImportError, "Question text is required" if text.blank?
    raise ImportError, "Response type is required" if response_type.blank?

    # Validate response_type
    unless Question.response_types.keys.include?(response_type)
      raise ImportError, "Invalid response_type: #{response_type}. Must be one of: #{Question.response_types.keys.join(', ')}"
    end

    # Validate code format
    unless code.match?(/\A[A-Z0-9_]+\z/)
      raise ImportError, "Invalid code format: #{code}. Must contain only uppercase letters, numbers, and underscores"
    end

    # Find or initialize question (idempotent - update existing by code)
    question = Question.find_by(code: code)
    was_new = question.nil?

    if question.nil?
      # Create new question
      question_params = {
        code: code,
        text: text,
        response_type: response_type,
        position: question_data['position']&.to_i
      }

      question = QuestionManagementService.create_question(domain, question_params)
      result[:imported] = true
      @imported_questions << question
    else
      # Update existing question (idempotent re-import)
      if question.profile_domain_id != domain.id
        result[:warnings] << {
          code: code,
          message: "Question belongs to different domain (#{question.profile_domain.key}). Moving to #{domain.key}"
        }
      end

      question.update!(
        profile_domain_id: domain.id,
        domain: domain.key,
        text: text,
        response_type: response_type,
        position: question_data['position']&.to_i || question.position
      )
      result[:updated] = true
      @updated_questions << question

      # Clear existing options if we're updating (re-import replaces options)
      question.question_options.destroy_all if question_data['options'].present?
    end

    # Validate and import options
    options_data = question_data['options'] || []

    # Validate options are required for scale/multi_choice
    if (response_type == 'scale' || response_type == 'multi_choice') && options_data.empty?
      if was_new
        raise ImportError, "#{response_type.capitalize} questions require at least one option"
      else
        result[:warnings] << {
          code: code,
          message: "Existing #{response_type} question has no options. Options should be provided."
        }
      end
    end

    # Import options if provided
    if options_data.any?
      options_data.each_with_index do |option_data, index|
        option_label = option_data['label']&.strip
        option_value = option_data['value']
        option_position = option_data['position']&.to_i || index

        raise ImportError, "Option #{index + 1} label is required" if option_label.blank?
        raise ImportError, "Option #{index + 1} value is required" if option_value.nil?

        QuestionOption.create!(
          question: question,
          label: option_label,
          value: option_value.to_i,
          position: option_position
        )
      end

      # Normalize option positions (ensure sequential 0-based positions)
      question.question_options.ordered.each_with_index do |option, index|
        option.update_column(:position, index) if option.position != index
      end
    end

    result[:question] = question.reload
    result
  end
end
