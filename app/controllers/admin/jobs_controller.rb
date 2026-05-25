module Admin
  class JobsController < ApplicationController
    before_action :set_job, only: [:show, :edit, :update, :release, :destroy]

    def index
      @jobs = Job.includes(:job_processes).order(created_at: :desc)
    end

    def new
      @job = Job.new(
        status: "Draft",
        due_date: Date.current
      )

      @selected_process_codes = []
    end

    def create
      @job = Job.new(job_params)
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
    end

    def edit
      @selected_process_codes = @job.job_processes.pluck(:process_code)
    end

    def update
      @selected_process_codes = selected_process_codes

      if @selected_process_codes.empty?
        @job.errors.add(:base, "Please select at least one process.")
        render :edit, status: :unprocessable_entity
        return
      end

      ActiveRecord::Base.transaction do
        @job.update!(job_params)
        sync_job_processes(@job, @selected_process_codes)
      end

      redirect_to admin_job_path(@job), notice: "Job updated successfully."
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    def release
      @job = Job.find(params[:id])

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
      @job = Job.includes(:job_processes).find(params[:id])
    end

    def job_params
      params.require(:job).permit(
        :job_no,
        :customer_name,
        :due_date,
        :notes
      )
    end

    def selected_process_codes
      Array(params[:process_codes]).reject(&:blank?).uniq
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