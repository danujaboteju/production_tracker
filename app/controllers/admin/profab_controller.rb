module Admin
  class ProfabController < ApplicationController
    def index
      @filter_alert = nil
      @work_date = parse_filter_date
      @selected_month = params[:month].presence
      @filter_month_range = parse_filter_month
      @fabrication_log = FabricationLog.new(work_date: @work_date, work_type: "PROD")
      @active_fabricators = Fabricator.active.assigned_to_operation("PROFAB")
      @eligible_jobs = eligible_jobs
      @filter_jobs = filter_jobs
      @filter_fabricators = filter_fabricators
      @selected_job_id = params[:job_id].presence
      @selected_fabricator_id = params[:fabricator_id].presence
      @fabrication_logs = filtered_logs.to_a
      @log_entries = @fabrication_logs.size
      @total_hours = @fabrication_logs.sum { |log| log.duration_hours || 0 }
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
      Job
        .joins(:job_processes)
        .where(status: "In Progress", job_processes: { process_code: "PROFAB" })
        .where.not(job_processes: { status: ["Completed", "Cancelled"] })
        .distinct
        .order(:job_no)
    end

    def filter_jobs
      Job
        .joins(job_processes: :fabrication_logs)
        .where(fabrication_logs: { work_type: "PROD" })
        .distinct
        .order(:job_no)
    end

    def filter_fabricators
      logged_fabricator_ids = FabricationLog.select(:fabricator_id)
      Fabricator
        .where(active: true)
        .or(Fabricator.where(id: logged_fabricator_ids))
        .ordered
    end

    def filtered_logs
      logs = FabricationLog
        .includes(:fabricator, job_process: :job)
        .where(work_date: filter_date_scope)
        .ordered

      logs = logs.where(fabricator_id: @selected_fabricator_id) if @selected_fabricator_id.present?

      if @selected_job_id.present?
        logs = logs.joins(:job_process).where(work_type: "PROD", job_processes: { job_id: @selected_job_id })
      end

      logs
    end

    def filter_date_scope
      @filter_month_range || @work_date
    end
  end
end
