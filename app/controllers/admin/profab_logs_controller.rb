module Admin
  class ProfabLogsController < ApplicationController
    def create
      fabrication_log = FabricationLog.new
      attrs = assign_log_attributes(fabrication_log)

      if valid_for_save?(fabrication_log, attrs) && fabrication_log.save
        redirect_to return_to_path(date: fabrication_log.work_date), notice: "PROFAB log added successfully."
      else
        redirect_to return_to_path(date: redirect_work_date(fabrication_log)), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def update
      fabrication_log = FabricationLog.find(params[:id])
      original_fabricator_id = fabrication_log.fabricator_id
      attrs = assign_log_attributes(fabrication_log)

      if valid_for_save?(fabrication_log, attrs, original_fabricator_id: original_fabricator_id) && fabrication_log.save
        redirect_to return_to_path(date: fabrication_log.work_date), notice: "PROFAB log updated successfully."
      else
        redirect_to return_to_path(date: redirect_work_date(fabrication_log)), alert: fabrication_log.errors.full_messages.to_sentence
      end
    end

    def destroy
      fabrication_log = FabricationLog.find(params[:id])
      work_date = fabrication_log.work_date
      fabrication_log.destroy!

      redirect_to return_to_path(date: work_date), notice: "PROFAB log deleted successfully."
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
        fabrication_log.job_process = eligible_profab_process_for(attrs[:job_id])
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

    def eligible_profab_process_for(job_id)
      return if job_id.blank?

      JobProcess
        .joins(:job)
        .where(job_id: job_id, process_code: "PROFAB", jobs: { status: "In Progress" })
        .where.not(status: ["Completed", "Cancelled"])
        .order(:id)
        .first
    end

    def valid_for_save?(fabrication_log, attrs, original_fabricator_id: nil)
      fabrication_log.valid?

      if fabrication_log.fabricator_id.present? && fabrication_log.fabricator_id != original_fabricator_id && !profab_team_member?(fabrication_log.fabricator_id)
        fabrication_log.errors.add(:fabricator, "must be an active Team Member assigned to PROFAB")
      end

      if attrs[:work_type] == "PROD" && attrs[:job_id].present? && fabrication_log.job_process.blank?
        fabrication_log.errors.add(:base, "Selected job is no longer eligible for PROFAB logging")
      end

      fabrication_log.errors.empty?
    end

    def profab_team_member?(fabricator_id)
      Fabricator.active.assigned_to_operation("PROFAB").exists?(id: fabricator_id)
    end

    def redirect_work_date(fabrication_log)
      fabrication_log.work_date.presence || Date.current
    end

    def return_to_path(date:)
      return_to = params[:return_to].to_s
      profab_path = admin_profab_path
      return return_to if return_to == profab_path || return_to.start_with?("#{profab_path}?")

      admin_profab_path(date: date)
    end
  end
end

