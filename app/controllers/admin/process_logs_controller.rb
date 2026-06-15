module Admin
  class ProcessLogsController < BaseController
    include ProcessLogging

    before_action :set_process_logging_config

    def index
      @filter_alert = nil
      @work_date = parse_filter_date
      @fabrication_log = FabricationLog.new(work_date: @work_date, work_type: "PROD")
      @work_types = FabricationLog::WORK_TYPES
      @active_fabricators = active_process_fabricators
      @eligible_jobs = eligible_jobs
      @fabrication_logs = process_log_scope.ordered.limit(20).to_a

      render "admin/profab/index"
    end

    private

    def parse_filter_date
      raw_date = params[:date].presence || params[:work_date].presence
      return Date.current if raw_date.blank?

      Date.iso8601(raw_date)
    rescue ArgumentError
      add_filter_alert("Invalid date filter. Showing today's logs instead.")
      Date.current
    end

    def add_filter_alert(message)
      @filter_alert = [@filter_alert, message].compact.join(" ")
    end

    def eligible_jobs
      Job
        .joins(:job_processes)
        .where(job_processes: { process_code: @process_code })
        .where(status: ["In Progress", "On Hold", "Completed"])
        .where.not(job_processes: { status: "Cancelled" })
        .distinct
        .order(:job_no)
    end

    def active_process_fabricators
      Fabricator
        .joins(:fabricator_operations)
        .where(active: true, fabricator_operations: { operation_code: @process_code })
        .order(:name)
        .to_a
        .uniq(&:id)
    end

    def process_log_scope
      FabricationLog
        .includes(:fabricator, job_process: :job)
        .joins(:job_process)
        .where(job_processes: { process_code: @process_code })
    end

    def profab?
      @process_code == "PROFAB"
    end
  end
end
