module Admin
  class JobsController < BaseController
    before_action :set_job, only: [:show, :edit, :update, :release, :destroy]

    def index
      @status = params[:status].presence || "In Progress"
      @status_tabs = [
        ["All Jobs", "All"],
        ["Released", "Released"],
        ["In Progress", "In Progress"],
        ["On Hold", "On Hold"],
        ["Completed", "Completed"]
      ]

      @status_counts = Job.group(:status).count
      @all_jobs_count = Job.count

      @jobs = Job.includes(:job_processes)
      @jobs = @jobs.where(status: @status) unless @status == "All"

      @jobs =
        if @status == "In Progress"
          @jobs
            .left_joins(:job_processes)
            .select("jobs.*")
            .group("jobs.id")
            .order(Arel.sql(progress_order_sql))
        else
          @jobs.order(created_at: :desc)
        end
    end

    def new
      @job = Job.new(
        status: "Draft",
        due_date: Date.current
      )

      @selected_process_codes = []
    end

    def create
      @job = Job.new(job_params.except(:status))
      @job.status = "Draft"

      @selected_process_codes = selected_process_codes

      if @selected_process_codes.empty?
        @job.errors.add(:base, "Please select at least one process.")
        render :new, status: :unprocessable_entity
        return
      end

      ActiveRecord::Base.transaction do
        @job.save!

        @selected_process_codes.each do |code|
          @job.job_processes.create!(
            process_code: code,
            process_name: JobProcess.process_name_for(code),
            status: "Draft"
          )
        end
      end

      redirect_to admin_job_path(@job), notice: "Job created successfully."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def show
      @active_fabricators = Fabricator.active.assigned_to_operation("PROFAB")
      @production_log_processes = @job.job_processes
        .where(process_code: Admin::ProcessLogging::PROCESS_CONFIG.keys)
        .order(:stage_no, :id)
      @production_logs = FabricationLog
        .joins(:job_process)
        .includes(:fabricator, :job_process)
        .where(job_processes: { job_id: @job.id, process_code: Admin::ProcessLogging::PROCESS_CONFIG.keys })
        .where.not(job_process_id: nil)
        .ordered
        .to_a
      @production_log = FabricationLog.new(work_date: Date.current)
      @fabricators = Fabricator.ordered
    end

    def edit
      @selected_process_codes = @job.job_processes.pluck(:process_code)
    end

    def update
      @selected_process_codes = selected_process_codes

      if status_only_update? && !manual_job_status?
        redirect_to admin_job_path(@job), alert: "Job status can only be manually set to On Hold, Completed, or Cancelled."
        return
      end

      if syncing_processes? && @selected_process_codes.empty?
        @job.errors.add(:base, "Please select at least one process.")
        render :edit, status: :unprocessable_entity
        return
      end

      if status_only_update? && params.dig(:job, :status) == "Completed"
        @job.complete!
      else
        ActiveRecord::Base.transaction do
          @job.update!(update_job_params)
          sync_job_processes(@job, @selected_process_codes) if syncing_processes?
        end
      end

      redirect_to admin_job_path(@job), notice: "Job updated successfully."
    rescue ActiveRecord::RecordInvalid
      if syncing_processes?
        render :edit, status: :unprocessable_entity
      else
        redirect_to admin_job_path(@job), alert: "Job could not be updated."
      end
    end

    def release
      if @job.release!
        redirect_to admin_job_path(@job), notice: "Job released successfully."
      else
        redirect_to admin_job_path(@job), alert: "Only Draft jobs can be released."
      end
    end

    def destroy
      job_no = @job.job_no
      @job.destroy!

      redirect_to admin_jobs_path, notice: "Job #{job_no} was deleted successfully."
    end

    private

    def set_job
      @job = Job.includes(job_processes: { fabrication_logs: :fabricator }).find(params[:id])
    end

    def job_params
      params.require(:job).permit(
        :job_no,
        :customer_name,
        :due_date,
        :status,
        :notes
      )
    end

    def selected_process_codes
      Array(params[:process_codes]).reject(&:blank?).uniq
    end

    def syncing_processes?
      @job&.status == "Draft" && params.key?(:process_codes)
    end

    def status_only_update?
      params.dig(:job, :status).present? && !job_detail_update? && !syncing_processes?
    end

    def job_detail_update?
      job_payload = params[:job] || {}
      ["job_no", "customer_name", "due_date", "notes"].any? { |key| job_payload.key?(key) }
    end

    def update_job_params
      status_only_update? ? job_params : job_params.except(:status)
    end

    def manual_job_status?
      params.dig(:job, :status).in?(["On Hold", "Completed", "Cancelled"])
    end

    def progress_order_sql
      completed_count_sql = "SUM(CASE WHEN job_processes.status = 'Completed' THEN 1 ELSE 0 END)"
      total_count_sql = "COUNT(job_processes.id)"

      <<~SQL.squish
        CASE
          WHEN #{total_count_sql} = 0 THEN 0
          ELSE #{completed_count_sql}::float / #{total_count_sql}
        END ASC,
        jobs.created_at DESC,
        jobs.id ASC
      SQL
    end

    def sync_job_processes(job, process_codes)
      existing_processes = job.job_processes.index_by(&:process_code)

      job.job_processes.where.not(process_code: process_codes).destroy_all

      process_codes.each do |code|
        next if existing_processes[code].present?

        if job.status == "Draft"
          job.job_processes.create!(
            process_code: code,
            process_name: JobProcess.process_name_for(code),
            status: "Draft"
          )
        else
          job.job_processes.create!(
            process_code: code,
            process_name: JobProcess.process_name_for(code),
            status: "Posted",
            posted_at: Time.current
          )
        end
      end
    end
  end
end