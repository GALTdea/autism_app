module ApplicationHelper
  def answer_display(answer)
    if answer.question_option.present?
      display_text = answer.question_option.label
      if answer.question_option.value.present?
        display_text += " (#{answer.question_option.value})"
      end
      content_tag :span, display_text,
        class: "inline-block px-3 py-1 bg-blue-100 text-blue-800 rounded-md text-sm font-medium print:bg-gray-100 print:text-gray-800"
    elsif answer.numeric_value.present?
      content_tag :span, answer.numeric_value.to_s,
        class: "inline-block px-3 py-1 bg-green-100 text-green-800 rounded-md text-sm font-medium print:bg-gray-100 print:text-gray-800"
    elsif answer.free_text.present?
      content_tag :div, simple_format(answer.free_text),
        class: "bg-white rounded-md p-3 border border-gray-200 text-sm text-gray-700 print:bg-gray-50 print:border-gray-400"
    else
      content_tag :span, "No answer provided", class: "text-gray-400 text-sm italic"
    end
  end
end
