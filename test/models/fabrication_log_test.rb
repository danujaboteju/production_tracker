require "test_helper"

class FabricationLogTest < ActiveSupport::TestCase
  setup do
    @fabricator = Fabricator.create!(name: "Model Welder")
    @job_process = create_job_process!
  end

  test "fabricator is required" do
    log = valid_prod_log(fabricator: nil)

    assert_not log.valid?
    assert_includes log.errors[:fabricator], "can't be blank"
  end

  test "PROD requires a job process" do
    log = valid_prod_log(job_process: nil)

    assert_not log.valid?
    assert log.errors[:job_process].present?
  end

  test "PROD does not allow other job name" do
    log = valid_prod_log(other_job_name: "Bench repair")

    assert_not log.valid?
    assert log.errors[:other_job_name].present?
  end

  test "Other requires other job name" do
    log = valid_other_log(other_job_name: "")

    assert_not log.valid?
    assert log.errors[:other_job_name].present?
  end

  test "Other does not allow a job process" do
    log = valid_other_log(job_process: @job_process)

    assert_not log.valid?
    assert log.errors[:job_process].present?
  end

  test "end time must be after start time" do
    log = valid_prod_log(start_time: "10:00", end_time: "09:00")

    assert_not log.valid?
    assert_includes log.errors[:end_time], "must be after start time"
  end

  test "open logs remain valid" do
    log = valid_prod_log(end_time: nil)

    assert log.valid?
  end

  test "duration hours returns decimal hours" do
    log = valid_prod_log(start_time: "08:15", end_time: "10:45")

    assert_equal BigDecimal("2.5"), log.duration_hours
  end

  private

  def valid_prod_log(overrides = {})
    FabricationLog.new({
      fabricator: @fabricator,
      job_process: @job_process,
      work_type: "PROD",
      work_date: Date.current,
      start_time: "08:00",
      end_time: "10:00"
    }.merge(overrides))
  end

  def valid_other_log(overrides = {})
    FabricationLog.new({
      fabricator: @fabricator,
      job_process: nil,
      work_type: "Other",
      other_job_name: "Workshop cleanup",
      work_date: Date.current,
      start_time: "08:00",
      end_time: "10:00"
    }.merge(overrides))
  end

  def create_job_process!
    job = Job.create!(job_no: "LOG-#{SecureRandom.hex(4)}", customer_name: "Laser Link", due_date: Date.current, status: "Draft")
    job.job_processes.create!(process_code: "PROFAB", status: "Draft")
  end
end
