class QuestionOptionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :question_id, form: true, type: :select, collection: -> { Question.includes(:profile_domain).ordered.map { |q| ["#{q.code}: #{q.text.truncate(30)}", q.id] } }
  attribute :label
  attribute :value
  attribute :position
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :question, form: false
  attribute :answers, form: false

  # Note: Options are ordered by position via association

  # Customize the display name of records in the admin area.
  def self.display_name(record)
    record.label.presence || record.value
  end

  # Customize the default sort column and direction.
  def self.default_sort_column
    "position"
  end

  def self.default_sort_direction
    "asc"
  end
end
