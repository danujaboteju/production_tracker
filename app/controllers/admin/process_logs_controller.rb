module Admin
  class ProcessLogsController < BaseController
    include ProcessLogging

    before_action :set_process_logging_config

    def index
      @filter_alert = nil
      @work_date = parse_filter_date
      @selected_month = params[:month].presence
      @filter_month_range = parse_filter_month
      @fabrication_log = FabricationLog.new(work_date: @work_date, work_type: "PROD")
      @work_types = FabricationLog::WORK_TYPES
      @active_fabricators = active_process_fabricators
      @eligible_jobs = eligible_jobs
      @filter_jobs = filter_jobs
      @filter_fabricators = filter_fabricators
      @selected_job_id = params[:job_id].presence
      @selected_fabricator_id = params[:fabricator_id].presence
      @fabrication_logs = filtered_logs.to_a
      @log_entries = @fabrication_logs.size
      @total_hours = @fabrication_logs.sum { |log| log.duration_hours || 0 }

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

    def parse_filter_month
      return if @selected_month.blank?

      month = Date.strptime(@selected_month, "%Y-%m")
      month.beginning_of_month..month.end_of_month
    rescue ArgumentError
      @selected_month = nil
      add_filter_alert("Invalid month filter. Showing the selected date instead.")
      nil
    end

    def add_filter_alert(message)
      @filter_alert = [@filter_alert, message].compact.join(" ")
    end

    def eligible_jobs
      base_scope = Job
        .joins(:job_processes)
        .where(job_processes: { process_code: @process_code })

      in_progress_jobs = base_scope
        .where(status: "In Progress")
        .where.not(job_processes: { status: ["Completed", "Cancelled"] })

      completed_jobs = base_scope
        .where(status: "Completed", job_processes: { status: "Completed" })

      in_progress_jobs
        .or(completed_jobs)
        .distinct
        .order(:job_no)
    end

    def filter_jobs
      Job
        .joins(job_processes: :fabrication_logs)
        .where(job_processes: { process_code: @process_code })
        .where(fabrication_logs: { work_type: "PROD" })
        .distinct
        .order(:job_no)
    end

    def filter_fabricators
      logged_fabricators = Fabricator
        .where(id: logged_fabricator_ids)
        .order(:name)
        .to_a

      (active_process_fabricators + logged_fabricators)
        .uniq(&:id)
        .sort_by { |fabricator| fabricator.name.to_s.downcase }
    end

    def active_process_fabricators
      Fabricator
        .joins(:fabricator_operations)
        .where(active: true, fabricator_operations: { operation_code: @process_code })
        .order(:name)
        .to_a
        .uniq(&:id)
    end

    def logged_fabricator_ids
      scope = FabricationLog.left_outer_joins(:job_process)
        .where("job_processes.process_code = ? OR fabrication_logs.job_process_id IS NULL", @process_code)

      scope.pluck(:fabricator_id).compact.uniq
    end

    def filtered_logs
      logs = process_log_scope.where(work_date: filter_date_scope).ordered

      logs = logs.where(fabricator_id: @selected_fabricator_id) if @selected_fabricator_id.present?

      if @selected_job_id.present?
        logs = logs.where(work_type: "PROD", job_processes: { job_id: @selected_job_id })
      end

      logs
    end

    def process_log_scope
      scope = FabricationLog.includes(:fabricator, job_process: :job)

      scope
        .left_outer_joins(:job_process)
        .where("job_processes.process_code = ? OR fabrication_logs.job_process_id IS NULL", @process_code)
    end

    def filter_date_scope
      @filter_month_range || @work_date
    end

    def profab?
      @process_code == "PROFAB"
    end
  end
end
