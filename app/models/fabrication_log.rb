class FabricationLog < ApplicationRecord
  WORK_TYPES = ["PROD", "Other"].freeze
  SHOP_FLOOR_BREAK_WINDOWS = [
    [[10, 0], [10, 15]],
    [[13, 0], [13, 30]]
  ].freeze

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
    net_duration_seconds&./(1.hour)&.to_d
  end

  def gross_duration_hours
    gross_duration_seconds&./(1.hour)&.to_d
  end

  def break_duration_hours
    break_duration_seconds&./(1.hour)&.to_d
  end

  def net_duration_seconds
    return if gross_duration_seconds.blank?

    [gross_duration_seconds - break_duration_seconds, 0].max
  end

  def gross_duration_seconds
    return if start_time.blank? || end_time.blank?

    end_time - start_time
  end

  def break_duration_seconds
    return if start_time.blank? || end_time.blank?
    return 0 unless job_log?

    SHOP_FLOOR_BREAK_WINDOWS.sum do |(break_start_parts, break_end_parts)|
      break_start = time_on_log_day(*break_start_parts)
      break_end = time_on_log_day(*break_end_parts)
      overlap_start = [start_time, break_start].max
      overlap_end = [end_time, break_end].min

      [overlap_end - overlap_start, 0].max
    end
  end

  private

  def job_log?
    work_type == "PROD" || job_process_id.present?
  end

  def time_on_log_day(hour, min)
    start_time.change(hour: hour, min: min, sec: 0)
  end

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
