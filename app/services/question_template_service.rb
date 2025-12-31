class QuestionTemplateService
  # Common question templates for autism therapy domains
  TEMPLATES = {
    frequency_scale: {
      name: "Frequency Scale",
      description: "Questions about how often something occurs (Always, Often, Sometimes, Rarely, Never)",
      response_type: "scale",
      options: [
        { label: "Always", value: 4 },
        { label: "Often", value: 3 },
        { label: "Sometimes", value: 2 },
        { label: "Rarely", value: 1 },
        { label: "Never", value: 0 }
      ]
    },
    difficulty_scale: {
      name: "Difficulty Scale",
      description: "Questions about level of difficulty (Very Easy, Easy, Moderate, Difficult, Very Difficult)",
      response_type: "scale",
      options: [
        { label: "Very Easy", value: 0 },
        { label: "Easy", value: 1 },
        { label: "Moderate", value: 2 },
        { label: "Difficult", value: 3 },
        { label: "Very Difficult", value: 4 }
      ]
    },
    satisfaction_scale: {
      name: "Satisfaction Scale",
      description: "Questions about satisfaction level (Very Satisfied to Very Dissatisfied)",
      response_type: "scale",
      options: [
        { label: "Very Satisfied", value: 4 },
        { label: "Satisfied", value: 3 },
        { label: "Neutral", value: 2 },
        { label: "Dissatisfied", value: 1 },
        { label: "Very Dissatisfied", value: 0 }
      ]
    },
    yes_no: {
      name: "Yes/No",
      description: "Simple yes or no question",
      response_type: "multi_choice",
      options: [
        { label: "Yes", value: 1 },
        { label: "No", value: 0 }
      ]
    },
    yes_no_sometimes: {
      name: "Yes/No/Sometimes",
      description: "Yes, No, or Sometimes options",
      response_type: "multi_choice",
      options: [
        { label: "Yes", value: 2 },
        { label: "Sometimes", value: 1 },
        { label: "No", value: 0 }
      ]
    },
    text_response: {
      name: "Text Response",
      description: "Free-form text response question",
      response_type: "text",
      options: []
    }
  }.freeze

  def self.all_templates
    TEMPLATES
  end

  def self.template(key)
    TEMPLATES[key.to_sym]
  end

  def self.create_from_template(profile_domain, template_key, question_text: nil)
    template = TEMPLATES[template_key.to_sym]
    raise Error, "Template '#{template_key}' not found" unless template

    new(profile_domain).create_from_template(template, question_text)
  end

  def initialize(profile_domain)
    @profile_domain = profile_domain
    raise Error, "Profile domain is required" if @profile_domain.nil?
  end

  def create_from_template(template, question_text = nil)
    # Generate question code using the service's public method
    # We'll create with minimal params and let the service generate the code
    params = {
      text: question_text || "#{template[:name]} Question",
      response_type: template[:response_type]
    }

    question = QuestionManagementService.create_question(@profile_domain, params)

    # Now add options if template has them
    if template[:options].any?
      ActiveRecord::Base.transaction do
        template[:options].each_with_index do |option_data, index|
          question.question_options.create!(
            label: option_data[:label],
            value: option_data[:value],
            position: index
          )
        end

        question.reload
      rescue ActiveRecord::RecordInvalid => e
        raise Error, "Failed to add options to question: #{e.message}"
      end
    end

    question
  end

  class Error < StandardError; end
end
