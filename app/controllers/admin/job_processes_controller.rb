module Admin
  class JobProcessesController < BaseController
    before_action :set_job
    before_action :set_job_process

    def start
      unless @job_process.status == "Posted"
        return redirect_with_error("Only posted processes can be started.")
      end

      @job_process.update!(status: "In Progress")

      redirect_to admin_job_path(@job), notice: "#{@job_process.process_code} marked as In Progress."
    end

    def complete
      unless ["In Progress", "On Hold"].include?(@job_process.status)
        return redirect_with_error("Only in-progress or on-hold processes can be completed.")
      end

      ActiveRecord::Base.transaction do
        @job_process.update!(
          status: "Completed",
          completed_at: Time.current
        )
        @job.advance_after_process_completed!
      end

      redirect_to admin_job_path(@job), notice: "#{@job_process.process_code} marked as Completed."
    end

    def hold
      unless @job_process.status == "In Progress"
        return redirect_with_error("Only in-progress processes can be put on hold.")
      end

      if params[:hold_reason].blank?
        return redirect_with_error("Hold reason is required.")
      end

      @job_process.update!(
        status: "On Hold",
        hold_reason: params[:hold_reason]
      )

      redirect_to admin_job_path(@job), notice: "#{@job_process.process_code} put on hold."
    end

    def resume
      unless @job_process.status == "On Hold"
        return redirect_with_error("Only on-hold processes can be resumed.")
      end

      @job_process.update!(
        status: "In Progress",
        hold_reason: nil
      )

      redirect_to admin_job_path(@job), notice: "#{@job_process.process_code} resumed."
    end

    def reopen
      unless @job_process.status == "Completed"
        return redirect_with_error("Only completed processes can be reopened.")
      end

      @job_process.update!(
        status: "Posted",
        completed_at: nil
      )

      redirect_to admin_job_path(@job), notice: "#{@job_process.process_code} reopened."
    end

    private

    def set_job
      @job = Job.find(params[:job_id])
    end

    def set_job_process
      @job_process = @job.job_processes.find(params[:id])
    end

    def redirect_with_error(message)
      redirect_to admin_job_path(@job), alert: message
    end
  end
end