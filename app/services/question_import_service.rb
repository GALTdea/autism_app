require 'csv'

class QuestionImportService
  class Error < StandardError; end
  class ImportError < Error; end
  class InvalidFormatError < Error; end

  # Expected CSV format:
  # code,text,response_type,position,option_1_label,option_1_value,option_2_label,option_2_value,...
  # COMM_1,"How often does the child initiate communication?",scale,0,Always,4,Often,3,Sometimes,2,Rarely,1,Never,0
  # COMM_2,"Describe the child's communication style",text,1

  CSV_HEADERS = {
    code: 'code',
    text: 'text',
    response_type: 'response_type',
    position: 'position'
  }.freeze

  def self.import_from_csv(profile_domain, csv_file)
    new(profile_domain).import_from_csv(csv_file)
  end

  def initialize(profile_domain)
    @profile_domain = profile_domain
    raise Error, "Profile domain is required" if @profile_domain.nil?
    @errors = []
    @imported_count = 0
    @skipped_count = 0
  end

  def import_from_csv(csv_file)
    raise Error, "CSV file is required" if csv_file.nil?

    begin
      csv_content = csv_file.read
      csv_file.rewind # Reset file pointer for potential re-reading
    rescue => e
      raise ImportError, "Failed to read CSV file: #{e.message}"
    end

    begin
      csv_data = CSV.parse(csv_content, headers: true, header_converters: :downcase)
    rescue CSV::MalformedCSVError => e
      raise InvalidFormatError, "Invalid CSV format: #{e.message}"
    end

    # Validate headers
    validate_headers(csv_data.headers)

    results = {
      imported: [],
      errors: [],
      skipped: []
    }

    # Process each row independently to allow partial imports
    csv_data.each_with_index do |row, index|
      row_number = index + 2 # +2 because CSV is 1-indexed and we have headers

      begin
        ActiveRecord::Base.transaction do
          question = import_row(row, row_number)
          if question
            results[:imported] << { row: row_number, question: question }
            @imported_count += 1
          else
            results[:skipped] << { row: row_number, reason: "Question already exists or was skipped" }
            @skipped_count += 1
          end
        end
      rescue => e
        # Add error to results (transaction already rolled back)
        results[:errors] << { row: row_number, error: e.message }
        @errors << "Row #{row_number}: #{e.message}"
      end
    end

    # If no questions were imported at all, raise an error
    if @imported_count == 0 && results[:errors].any?
      raise ImportError, "Import failed: No questions were imported. #{results[:errors].first[:error]}"
    end

    results
  rescue ActiveRecord::RecordInvalid => e
    raise ImportError, "Validation error: #{e.message}"
  rescue StandardError => e
    raise ImportError, "Unexpected error during import: #{e.message}"
  end

  private

  def validate_headers(headers)
    required_headers = [CSV_HEADERS[:code], CSV_HEADERS[:text], CSV_HEADERS[:response_type]]
    missing_headers = required_headers - headers.map(&:downcase)

    if missing_headers.any?
      raise InvalidFormatError, "Missing required headers: #{missing_headers.join(', ')}"
    end
  end

  def import_row(row, row_number)
    # Extract basic question data
    code = row[CSV_HEADERS[:code]]&.strip
    text = row[CSV_HEADERS[:text]]&.strip
    response_type = row[CSV_HEADERS[:response_type]]&.strip&.downcase
    position_str = row[CSV_HEADERS[:position]]&.strip

    # Validate required fields
    raise ImportError, "Code is required" if code.blank?
    raise ImportError, "Text is required" if text.blank?
    raise ImportError, "Response type is required" if response_type.blank?

    # Validate response_type
    unless Question.response_types.keys.include?(response_type)
      raise ImportError, "Invalid response_type: #{response_type}. Must be one of: #{Question.response_types.keys.join(', ')}"
    end

    # Check if question already exists
    if Question.exists?(code: code)
      raise ImportError, "Question with code '#{code}' already exists"
    end

    # Parse position (optional, will auto-assign if blank)
    position = position_str.present? ? position_str.to_i : nil

    # Extract options from row
    options = extract_options(row, response_type)

    # Validate options for scale/multi_choice questions
    if (response_type == 'scale' || response_type == 'multi_choice') && options.empty?
      raise ImportError, "#{response_type.capitalize} questions require at least one option"
    end

    # Create question using QuestionManagementService
    question_params = {
      code: code,
      text: text,
      response_type: response_type,
      position: position
    }

    question = QuestionManagementService.create_question(@profile_domain, question_params)

    # Create options if they exist
    if options.any?
      options.each_with_index do |option_data, index|
        QuestionOption.create!(
          question: question,
          label: option_data[:label],
          value: option_data[:value],
          position: index
        )
      end
    end

    question.reload
  end

  def extract_options(row, response_type)
    options = []

    # Options are stored as pairs: option_1_label, option_1_value, option_2_label, option_2_value, ...
    # We'll look for columns matching pattern: option_*_label and option_*_value
    option_columns = row.headers.select { |h| h.match?(/^option_\d+_(label|value)$/) }

    # Group by option number
    option_numbers = option_columns.map { |h| h.match(/^option_(\d+)_/)[1] }.uniq.sort

    option_numbers.each do |num|
      label_key = "option_#{num}_label"
      value_key = "option_#{num}_value"

      label = row[label_key]&.strip
      value_str = row[value_key]&.strip

      # Skip if both are blank
      next if label.blank? && value_str.blank?

      # Label is required
      if label.blank?
        raise ImportError, "Option #{num} has a value but no label"
      end

      # Value is required and must be numeric
      if value_str.blank?
        raise ImportError, "Option #{num} has a label but no value"
      end

      begin
        value = Integer(value_str)
      rescue ArgumentError
        raise ImportError, "Option #{num} value must be a number, got: #{value_str}"
      end

      options << { label: label, value: value }
    end

    options
  end
end
