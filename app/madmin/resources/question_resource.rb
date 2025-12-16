class QuestionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :code
  attribute :text
  attribute :profile_domain_id, form: true, type: :select, collection: -> { ProfileDomain.ordered.map { |d| [d.label, d.id] } }
  attribute :response_type, form: true, type: :select, collection: Question.response_types.keys.map { |k| [k.humanize, k] }
  attribute :position
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :profile_domain, form: false
  attribute :question_options, form: false
  attribute :answers, form: false

  # Note: Use model scope (Question.ordered) in controllers

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    "#{record.code}: #{record.text.truncate(50)}"
  end

  # Customize the default sort column and direction.
  def self.default_sort_column
    "position"
  end

  def self.default_sort_direction
    "asc"
  end
end
