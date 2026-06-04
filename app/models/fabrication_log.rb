class FabricationLog < ApplicationRecord
  WORK_TYPES = ["PROD", "Other"].freeze

  belongs_to :fabricator
  belongs_to :job_process, optional: true

  validates :work_date, :start_time, :fabricator, presence: true
  validates :work_type, presence: true, inclusion: { in: WORK_TYPES }
  validate :end_time_after_start_time
  validate :work_type_fields

  scope :open, -> { where(end_time: nil) }
  scope :ordered, -> { order(work_date: :desc, start_time: :desc) }

  def open?
    end_time.blank?
  end

  def duration_hours
    return if start_time.blank? || end_time.blank?

    ((end_time - start_time) / 1.hour).to_d
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end

  def work_type_fields
    case work_type
    when "PROD"
      errors.add(:job_process, "must exist for PROD logs") if job_process.blank?
      errors.add(:other_job_name, "must be blank for PROD logs") if other_job_name.present?
    when "Other"
      errors.add(:job_process, "must be blank for Other logs") if job_process.present?
      errors.add(:other_job_name, "can't be blank for Other logs") if other_job_name.blank?
    end
  end
end
