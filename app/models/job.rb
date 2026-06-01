class Job < ApplicationRecord
  has_many :job_processes, dependent: :destroy

  STATUSES = [
    "Draft",
    "Released",
    "In Progress",
    "Completed",
    "On Hold",
    "Cancelled"
  ].freeze

  validates :job_no, presence: true
  validates :customer_name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  def process_codes
    job_processes.pluck(:process_code)
  end

  def release!
    return false unless status == "Draft"

    transaction do
      update!(status: "In Progress")

      job_processes.where(status: "Draft").update_all(
        status: "Posted",
        posted_at: Time.current,
        completed_at: nil,
        hold_reason: nil,
        updated_at: Time.current
      )

      start_next_posted_stage!
    end

    true
  end

  def complete!
    transaction do
      update!(status: "Completed")

      now = Time.current

      job_processes.find_each do |process|
        process.update!(
          status: "Completed",
          posted_at: process.posted_at || now,
          completed_at: process.completed_at || now,
          hold_reason: nil
        )
      end
    end
  end

  def advance_after_process_completed!
    transaction do
      if job_processes.where.not(status: ["Completed", "Cancelled"]).exists?
        start_next_posted_stage! unless job_processes.where(status: ["In Progress", "On Hold"]).exists?
        refresh_progress_status!
      else
        update!(status: "Completed")
      end
    end
  end

  def start_next_posted_stage!
    next_stage_no = job_processes.where(status: "Posted").minimum(:stage_no)
    return if next_stage_no.blank?

    job_processes.where(status: "Posted", stage_no: next_stage_no).update_all(
      status: "In Progress",
      updated_at: Time.current
    )
  end

  def ordered_job_processes
    job_processes.order(:stage_no, :id).to_a
  end

  def refresh_progress_status!
    return if status.in?(["Draft", "Completed", "Cancelled"])

    active_processes = job_processes.where.not(status: "Cancelled")

    progress_status =
      if active_processes.exists? && active_processes.where.not(status: "Completed").none?
        "Completed"
      elsif job_processes.where(status: ["In Progress", "Partially Completed", "Completed", "On Hold"]).exists?
        "In Progress"
      elsif job_processes.where(status: "Posted").exists?
        "In Progress"
      else
        status
      end

    update!(status: progress_status) if progress_status != status
  end
end
