class QuestionOptionService
  class Error < StandardError; end
  class InvalidOptionError < Error; end
  class UpdateError < Error; end
  class DeleteError < Error; end

  def self.create_option(question, params)
    new(question).create_option(params)
  end

  def self.update_option(option, params)
    new(option.question).update_option(option, params)
  end

  def self.reorder_options(question, positions)
    new(question).reorder_options(positions)
  end

  def self.delete_option(option)
    new(option.question).delete_option(option)
  end

  def initialize(question)
    @question = question
    raise Error, "Question is required" if @question.nil?
  end

  def create_option(params)
    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Auto-assign position if not provided
      params['position'] ||= next_position

      # Ensure question_id is set
      params['question_id'] = @question.id

      # Ensure value is an integer
      params['value'] = params['value'].to_i if params['value'].present?

      option = QuestionOption.new(params)
      option.save!

      # Renormalize positions after creation
      normalize_positions

      option
    rescue ActiveRecord::RecordInvalid => e
      raise InvalidOptionError, "Failed to create option: #{e.message}"
    rescue StandardError => e
      raise InvalidOptionError, "Unexpected error creating option: #{e.message}"
    end
  end

  def update_option(option, params)
    raise InvalidOptionError, "Option does not belong to this question" unless option.question_id == @question.id

    params = params.stringify_keys

    ActiveRecord::Base.transaction do
      # Don't allow changing question_id
      params.delete('question_id')
      params.delete('question')

      # Ensure value is an integer if provided
      params['value'] = params['value'].to_i if params['value'].present?

      option.update!(params)

      # Renormalize positions after update (in case position changed)
      normalize_positions

      option
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to update option: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error updating option: #{e.message}"
    end
  end

  def reorder_options(positions)
    # positions should be a hash: { option_id => position }
    positions = positions.stringify_keys

    ActiveRecord::Base.transaction do
      positions.each do |option_id, position|
        option = @question.question_options.find_by(id: option_id)
        next unless option

        new_position = position.to_i
        option.update!(position: new_position)
      end

      # Renormalize positions to ensure they're sequential starting from 0
      normalize_positions

      @question.question_options.ordered
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to reorder options: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error during reordering: #{e.message}"
    end
  end

  def delete_option(option)
    raise InvalidOptionError, "Option does not belong to this question" unless option.question_id == @question.id
    raise DeleteError, "Cannot delete option that has answers" if option.answers.any?

    ActiveRecord::Base.transaction do
      option.destroy!

      # Renormalize positions after deletion
      normalize_positions

      option
    rescue ActiveRecord::RecordInvalid => e
      raise DeleteError, "Failed to delete option: #{e.message}"
    rescue StandardError => e
      raise DeleteError, "Unexpected error deleting option: #{e.message}"
    end
  end

  private

  def next_position
    # Get the maximum position for options in this question, add 1
    max_position = @question.question_options.maximum(:position)
    (max_position || -1) + 1
  end

  def normalize_positions
    # Ensure positions are sequential starting from 0
    @question.question_options.ordered.each_with_index do |option, index|
      option.update_column(:position, index)
    end
  end
end
