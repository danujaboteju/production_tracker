class FabricationLog < ApplicationRecord
  belongs_to :job_process

  validates :work_date, :start_time, :fabricator_name, presence: true
  validate :end_time_after_start_time

  scope :open, -> { where(end_time: nil) }
  scope :ordered, -> { order(work_date: :desc, start_time: :desc) }

  def open?
    end_time.blank?
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
