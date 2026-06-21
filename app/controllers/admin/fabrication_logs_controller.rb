module Admin
  class FabricationLogsController < BaseController
    LOGGABLE_PROCESS_CODES = Admin::ProcessLogging::PROCESS_CONFIG.keys.freeze

    before_action :set_job

    def create
      job_process = selected_job_process
      unless job_process
        redirect_to admin_job_path(@job), alert: "Please select a valid process for this job."
        return
      end

      fabrication_log = FabricationLog.new(
        fabrication_log_params.merge(work_type: "PROD", other_job_name: nil)
      )
      fabrication_log.job_process = job_process

      if valid_for_save?(fabrication_log) && fabrication_log.save
        redirect_to admin_job_path(@job), notice: "Production log added successfully."
      else
        redirect_to admin_job_path(@job), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def update
      fabrication_log = job_production_logs.find(params[:id])
      original_fabricator_id = fabrication_log.fabricator_id
      original_process_code = fabrication_log.job_process&.process_code
      job_process = selected_job_process

      unless job_process
        redirect_to admin_job_path(@job), alert: "Please select a valid process for this job."
        return
      end

      fabrication_log.assign_attributes(
        fabrication_log_params.merge(work_type: "PROD", other_job_name: nil)
      )
      fabrication_log.job_process = job_process

      if valid_for_save?(fabrication_log, original_fabricator_id: original_fabricator_id, original_process_code: original_process_code) && fabrication_log.save
        redirect_to admin_job_path(@job), notice: "Production log updated successfully."
      else
        redirect_to admin_job_path(@job), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def destroy
      job_production_logs.find(params[:id]).destroy!

      redirect_to admin_job_path(@job), notice: "Production log deleted successfully."
    end

    private

    def set_job
      @job = Job.find(params[:job_id])
    end

    def selected_job_process
      if params[:job_process_id].present?
        @job.job_processes.where(process_code: LOGGABLE_PROCESS_CODES).find_by(id: params[:job_process_id])
      else
        @job.job_processes.where(process_code: LOGGABLE_PROCESS_CODES).find_by(process_code: selected_process_code)
      end
    end

    def selected_process_code
      params.dig(:fabrication_log, :process_code).presence
    end

    def job_production_logs
      FabricationLog
        .joins(:job_process)
        .where(job_processes: { job_id: @job.id, process_code: LOGGABLE_PROCESS_CODES })
    end

    def fabrication_log_params
      params.require(:fabrication_log).permit(
        :work_date,
        :start_time,
        :end_time,
        :fabricator_id,
        :note
      )
    end

    def valid_for_save?(fabrication_log, original_fabricator_id: nil, original_process_code: nil)
      fabrication_log.valid?
      process_code = fabrication_log.job_process&.process_code

      if fabrication_log.job_process.blank?
        fabrication_log.errors.add(:base, "Please select a valid process for this job.")
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
  end
end
