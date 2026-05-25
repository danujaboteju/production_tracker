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
      update!(status: "Released")

      job_processes.update_all(
        status: "Waiting",
        posted_at: nil,
        started_at: nil,
        completed_at: nil,
        updated_at: Time.current
      )

      unlock_next_stage!
      refresh_status!
    end

    true
  end

  def unlock_next_stage!
    active_processes = job_processes.where.not(status: ["Cancelled"])

    return if active_processes.empty?

    incomplete_processes = active_processes.where.not(status: "Completed")

    return if incomplete_processes.empty?

    next_stage_no = incomplete_processes.minimum(:stage_no)

    return if next_stage_no.blank?

    job_processes
      .where(stage_no: next_stage_no, status: "Waiting")
      .update_all(
        status: "Posted",
        posted_at: Time.current,
        updated_at: Time.current
      )
  end

  def refresh_status!
    processes = job_processes.to_a

    return update!(status: "Draft") if processes.empty?

    statuses = processes.map(&:status)

    new_status =
      if statuses.all? { |status| status == "Draft" }
        "Draft"
      elsif statuses.any? { |status| status == "On Hold" }
        "On Hold"
      elsif statuses.all? { |status| status == "Completed" }
        "Completed"
      elsif statuses.any? { |status| status == "In Progress" }
        "In Progress"
      elsif statuses.any? { |status| status == "Posted" }
        "Released"
      elsif statuses.any? { |status| status == "Waiting" }
        "Released"
      elsif statuses.all? { |status| status == "Cancelled" }
        "Cancelled"
      else
        status
      end

    update!(status: new_status) if status != new_status
  end
end