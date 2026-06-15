module Admin
  class ProductionLogsController < BaseController
    PROCESS_CONFIG = ProcessLogging::PROCESS_CONFIG

    def index
      load_index_data
      @fabrication_logs = filtered_logs.to_a
    end

    def update
      fabrication_log = FabricationLog.includes(:job_process).find(params[:id])
      original_fabricator_id = fabrication_log.fabricator_id
      original_process_code = fabrication_log.job_process&.process_code

      assign_log_attributes(fabrication_log)

      if valid_for_save?(fabrication_log, original_fabricator_id: original_fabricator_id, original_process_code: original_process_code) && fabrication_log.save
        redirect_to production_logs_return_to_path, notice: "Production log updated successfully."
      else
        redirect_to production_logs_return_to_path, alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    private

    def load_index_data
      @filter_alert = nil
      @date_from = parse_date(:date_from)
      @date_to = parse_date(:date_to)
      @selected_process_code = params[:process_code].presence
      @selected_job_id = params[:job_id].presence
      @selected_fabricator_id = params[:fabricator_id].presence

      @process_options = PROCESS_CONFIG.keys
      @jobs = Job.order(:job_no)
      @fabricators = Fabricator.ordered
    end

    def filtered_logs
      logs = FabricationLog
        .left_outer_joins(job_process: :job)
        .includes(:fabricator, job_process: :job)
        .ordered

      logs = logs.where("fabrication_logs.work_date >= ?", @date_from) if @date_from.present?
      logs = logs.where("fabrication_logs.work_date <= ?", @date_to) if @date_to.present?
      logs = logs.where(job_processes: { process_code: @selected_process_code }) if @selected_process_code.present?
      logs = logs.where(job_processes: { job_id: @selected_job_id }) if @selected_job_id.present?
      logs = logs.where(fabricator_id: @selected_fabricator_id) if @selected_fabricator_id.present?

      logs
    end

    def assign_log_attributes(fabrication_log)
      attrs = production_log_params
      process_code = attrs[:process_code].presence
      job_id = attrs[:job_id].presence

      fabrication_log.assign_attributes(
        attrs.except(:process_code, :job_id).merge(other_job_name: nil)
      )

      if process_code.present?
        fabrication_log.work_type = "PROD"
        fabrication_log.job_process = eligible_process_for(process_code, job_id)
        fabrication_log.other_job_name = nil
      else
        fabrication_log.work_type = "Other"
        fabrication_log.job_process = nil
        fabrication_log.other_job_name = fabrication_log.other_job_name.presence || "Other"
      end
    end

    def production_log_params
      params.require(:fabrication_log).permit(
        :work_date,
        :job_id,
        :process_code,
        :fabricator_id,
        :start_time,
        :end_time,
        :note
      )
    end

    def eligible_process_for(process_code, job_id)
      return if process_code.blank? || job_id.blank?

      JobProcess
        .joins(:job)
        .where(job_id: job_id, process_code: process_code)
        .where(jobs: { status: ["In Progress", "On Hold", "Completed"] })
        .where.not(status: "Cancelled")
        .order(:id)
        .first
    end

    def valid_for_save?(fabrication_log, original_fabricator_id:, original_process_code:)
      fabrication_log.valid?
      process_code = fabrication_log.job_process&.process_code

      if production_log_params[:process_code].present? && fabrication_log.job_process.blank?
        fabrication_log.errors.add(:base, "Selected job is not available for the selected process")
      end

      if process_code.present? && process_assignment_changed?(fabrication_log, original_fabricator_id, original_process_code) && !process_team_member?(fabrication_log.fabricator_id, process_code)
        fabrication_log.errors.add(:fabricator, "must be an active Team Member assigned to #{process_code}")
      end

      fabrication_log.errors.empty?
    end

    def process_assignment_changed?(fabrication_log, original_fabricator_id, original_process_code)
      fabrication_log.fabricator_id != original_fabricator_id || fabrication_log.job_process&.process_code != original_process_code
    end

    def process_team_member?(fabricator_id, process_code)
      Fabricator
        .joins(:fabricator_operations)
        .where(active: true, fabricator_operations: { operation_code: process_code })
        .exists?(id: fabricator_id)
    end

    def parse_date(param_key)
      raw_date = params[param_key].presence
      return if raw_date.blank?

      Date.iso8601(raw_date)
    rescue ArgumentError
      add_filter_alert("Invalid #{param_key.to_s.humanize.downcase}. That filter was ignored.")
      nil
    end

    def add_filter_alert(message)
      @filter_alert = [@filter_alert, message].compact.join(" ")
    end

    def production_logs_return_to_path
      return_to = params[:return_to].to_s
      production_logs_path = helpers.admin_production_logs_path
      return return_to if return_to == production_logs_path || return_to.start_with?("#{production_logs_path}?")

      production_logs_path
    end
  end
end
