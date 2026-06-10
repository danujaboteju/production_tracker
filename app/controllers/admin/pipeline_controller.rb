module Admin
  class PipelineController < BaseController
    def index
      @process_options = JobProcess::PROCESS_OPTIONS

      @visible_statuses = [
        "Posted",
        "In Progress",
        "Partially Completed",
        "On Hold"
      ]

      @job_processes_by_code =
        JobProcess
          .includes(:job)
          .joins(:job)
          .where(status: @visible_statuses)
          .where(process_code: @process_options.keys)
          .order(Arel.sql("jobs.due_date ASC NULLS LAST, job_processes.posted_at ASC NULLS LAST, job_processes.id ASC"))
          .group_by(&:process_code)
    end
  end
end