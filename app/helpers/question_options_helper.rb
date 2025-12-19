module QuestionOptionsHelper
  # Auto-generate the next value for a scale question option
  # Returns a suggested value based on existing options
  def next_scale_value(question)
    return 4 if question.question_options.empty?

    existing_values = question.question_options.pluck(:value).sort.reverse
    max_value = existing_values.first || 0

    # For scale questions, suggest descending values (highest first)
    # Start from max + 1, but also consider common patterns (0-4 or 0-5)
    if max_value >= 4
      # Already have high values, suggest the next increment or go down if needed
      max_value + 1 <= 5 ? max_value + 1 : 4
    elsif max_value >= 0
      # Suggest the next value in a typical 0-4 or 0-5 scale
      max_value + 1
    else
      4 # Default starting value for scales
    end
  end

  # Auto-generate the next value for a multi-choice question option
  def next_multi_choice_value(question)
    return 1 if question.question_options.empty?

    existing_values = question.question_options.pluck(:value).sort.reverse
    max_value = existing_values.first || 0

    max_value + 1
  end

  # Suggest the next value based on question response type
  def suggested_option_value(question)
    case question.response_type
    when 'scale'
      next_scale_value(question)
    when 'multi_choice'
      next_multi_choice_value(question)
    else
      0
    end
  end

  # Suggest label based on value for scale questions
  def suggested_scale_label(value)
    scale_labels = {
      5 => "Always",
      4 => "Very Often",
      3 => "Often",
      2 => "Sometimes",
      1 => "Rarely",
      0 => "Never"
    }

    scale_labels[value] || "Option #{value}"
  end

  # Validate if a value is appropriate for a scale question
  def valid_scale_value?(value)
    value.is_a?(Integer) && value >= 0 && value <= 5
  end

  # Get the typical value range for a response type
  def value_range_for_type(response_type)
    case response_type
    when 'scale'
      { min: 0, max: 5, typical_max: 4, description: "0-4 or 0-5" }
    when 'multi_choice'
      { min: 0, max: nil, typical_max: nil, description: "Any positive number" }
    else
      { min: 0, max: nil, typical_max: nil, description: "N/A" }
    end
  end

  # Check if a value is within the typical range for scale questions
  def value_in_typical_range?(value, response_type)
    return true unless response_type == 'scale'
    valid_scale_value?(value) && value <= 5
  end

  # Generate common scale options as suggestions
  def common_scale_options
    [
      { label: "Always", value: 4 },
      { label: "Often", value: 3 },
      { label: "Sometimes", value: 2 },
      { label: "Rarely", value: 1 },
      { label: "Never", value: 0 }
    ]
  end
end
