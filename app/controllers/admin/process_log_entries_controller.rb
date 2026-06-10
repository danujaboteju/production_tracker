module Admin
  class ProcessLogEntriesController < BaseController
    include ProcessLogging

    before_action :set_process_logging_config

    def create
      fabrication_log = FabricationLog.new
      attrs = assign_log_attributes(fabrication_log)

      if valid_for_save?(fabrication_log, attrs) && fabrication_log.save
        redirect_to process_return_to_path(date: fabrication_log.work_date), notice: "#{@process_code} log added successfully."
      else
        redirect_to process_return_to_path(date: redirect_work_date(fabrication_log)), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def update
      fabrication_log = process_logs.find(params[:id])
      original_fabricator_id = fabrication_log.fabricator_id
      attrs = assign_log_attributes(fabrication_log)

      if valid_for_save?(fabrication_log, attrs, original_fabricator_id: original_fabricator_id) && fabrication_log.save
        redirect_to process_return_to_path(date: fabrication_log.work_date), notice: "#{@process_code} log updated successfully."
      else
        redirect_to process_return_to_path(date: redirect_work_date(fabrication_log)), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def destroy
      fabrication_log = process_logs.find(params[:id])
      work_date = fabrication_log.work_date
      fabrication_log.destroy!

      redirect_to process_return_to_path(date: work_date), notice: "#{@process_code} log deleted successfully."
    end

    private

    def assign_log_attributes(fabrication_log)
      attrs = fabrication_log_params
      work_type = attrs[:work_type].presence || "PROD"
      attrs[:work_type] = work_type

      fabrication_log.assign_attributes(
        attrs.except(:job_id, :other_job_name).merge(work_type: work_type)
      )

      if work_type == "PROD"
        fabrication_log.job_process = eligible_process_for(attrs[:job_id])
        fabrication_log.other_job_name = nil
      elsif work_type == "Other"
        fabrication_log.job_process = nil
        fabrication_log.other_job_name = attrs[:other_job_name].to_s.strip
      end

      attrs
    end

    def fabrication_log_params
      params.require(:fabrication_log).permit(
        :fabricator_id,
        :work_type,
        :job_id,
        :other_job_name,
        :work_date,
        :start_time,
        :end_time,
        :note
      )
    end

    def eligible_process_for(job_id)
      return if job_id.blank?

      base_scope = JobProcess
        .joins(:job)
        .where(job_id: job_id, process_code: @process_code)

      in_progress_processes = base_scope
        .where(jobs: { status: "In Progress" })
        .where.not(status: ["Completed", "Cancelled"])

      completed_processes = base_scope
        .where(status: "Completed", jobs: { status: "Completed" })

      in_progress_processes
        .or(completed_processes)
        .order(:id)
        .first
    end

    def valid_for_save?(fabrication_log, attrs, original_fabricator_id: nil)
      fabrication_log.valid?

      if fabrication_log.fabricator_id.present? && fabrication_log.fabricator_id != original_fabricator_id && !process_team_member?(fabrication_log.fabricator_id)
        fabrication_log.errors.add(:fabricator, "must be an active Team Member assigned to #{@process_code}")
      end

      if attrs[:work_type] == "PROD" && attrs[:job_id].present? && fabrication_log.job_process.blank?
        fabrication_log.errors.add(:base, "Selected job is no longer eligible for #{@process_code} logging")
      end


      fabrication_log.errors.empty?
    end

    def process_team_member?(fabricator_id)
      Fabricator
        .joins(:fabricator_operations)
        .where(active: true, fabricator_operations: { operation_code: @process_code })
        .exists?(id: fabricator_id)
    end

    def process_logs
      FabricationLog
        .left_outer_joins(:job_process)
        .where("job_processes.process_code = ? OR fabrication_logs.job_process_id IS NULL", @process_code)
    end

    def profab?
      @process_code == "PROFAB"
    end

    def redirect_work_date(fabrication_log)
      fabrication_log.work_date.presence || Date.current
    end

    def process_return_to_path(date:)
      return_to = params[:return_to].to_s
      process_path = process_log_index_path
      return return_to if return_to == process_path || return_to.start_with?("#{process_path}?")

      process_log_index_path(date: date)
    end
  end
end
