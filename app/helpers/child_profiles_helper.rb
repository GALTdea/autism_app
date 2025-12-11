module ChildProfilesHelper
  def domain_level_badge(level_estimate)
    case level_estimate
    when 0..1
      content_tag :span, "Needs Support", class: "px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800"
    when 2
      content_tag :span, "Developing", class: "px-3 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800"
    when 3
      content_tag :span, "Strong", class: "px-3 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800"
    else
      content_tag :span, "Very Strong", class: "px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800"
    end
  end

  def domain_level_percentage(level_estimate)
    # Convert 0-4 scale to percentage (0 = 0%, 4 = 100%)
    ((level_estimate.to_f / 4) * 100).round
  end

  def goal_status_badge(status)
    case status
    when "suggested"
      content_tag :span, "Suggested", class: "px-2 py-1 text-xs font-semibold rounded bg-gray-100 text-gray-800"
    when "active"
      content_tag :span, "Active", class: "px-2 py-1 text-xs font-semibold rounded bg-blue-100 text-blue-800"
    when "paused"
      content_tag :span, "Paused", class: "px-2 py-1 text-xs font-semibold rounded bg-yellow-100 text-yellow-800"
    when "archived"
      content_tag :span, "Archived", class: "px-2 py-1 text-xs font-semibold rounded bg-gray-100 text-gray-600"
    else
      content_tag :span, status.titleize, class: "px-2 py-1 text-xs font-semibold rounded bg-gray-100 text-gray-800"
    end
  end
end
