module Admin
  class FabricationLogsController < ApplicationController
    before_action :set_job
    before_action :set_job_process
    before_action :ensure_stage_four_process

    def create
      fabrication_log = @job_process.fabrication_logs.new(fabrication_log_params)

      if fabrication_log.save
        redirect_to admin_job_path(@job), notice: "Fabrication log added successfully."
      else
        redirect_to admin_job_path(@job), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def update
      fabrication_log = @job_process.fabrication_logs.find(params[:id])

      if fabrication_log.update(fabrication_log_params)
        redirect_to admin_job_path(@job), notice: "Fabrication log updated successfully."
      else
        redirect_to admin_job_path(@job), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def destroy
      @job_process.fabrication_logs.find(params[:id]).destroy!

      redirect_to admin_job_path(@job), notice: "Fabrication log deleted successfully."
    end

    private

    def set_job
      @job = Job.find(params[:job_id])
    end

    def set_job_process
      @job_process = @job.job_processes.find(params[:job_process_id])
    end

    def ensure_stage_four_process
      return if @job_process.stage_no == 4

      redirect_to admin_job_path(@job), alert: "Fabrication logs are only available for Stage 4 processes."
    end

    def fabrication_log_params
      params.require(:fabrication_log).permit(
        :work_date,
        :start_time,
        :end_time,
        :fabricator_name,
        :note
      )
    end
  end
end
