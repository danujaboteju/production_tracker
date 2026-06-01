module Admin::JobsHelper
  def job_status_badge_class(status)
    case status
    when "In Progress"
      "bg-yellow-100 text-yellow-800"
    when "Completed"
      "bg-green-100 text-green-800"
    when "On Hold"
      "bg-blue-100 text-blue-800"
    when "Cancelled"
      "bg-red-100 text-red-800"
    when "Released"
      "bg-slate-800 text-white"
    else
      "bg-slate-200 text-slate-700"
    end
  end
end
