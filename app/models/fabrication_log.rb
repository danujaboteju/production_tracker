class FabricationLog < ApplicationRecord
  belongs_to :job_process

  validates :work_date, :start_time, :end_time, :fabricator_name, presence: true
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
