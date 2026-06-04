require "test_helper"

class FabricatorTest < ActiveSupport::TestCase
  test "name is required" do
    fabricator = Fabricator.new(name: "")

    assert_not fabricator.valid?
    assert_includes fabricator.errors[:name], "can't be blank"
  end

  test "name is unique case insensitively" do
    Fabricator.create!(name: "Case Welder")
    fabricator = Fabricator.new(name: " case welder ")

    assert_not fabricator.valid?
    assert_includes fabricator.errors[:name], "has already been taken"
  end

  test "name is trimmed before validation" do
    fabricator = Fabricator.create!(name: "  Trimmed Welder  ")

    assert_equal "Trimmed Welder", fabricator.name
  end

  test "active scope includes active fabricators and excludes inactive fabricators" do
    active = Fabricator.create!(name: "Active Welder", active: true)
    inactive = Fabricator.create!(name: "Inactive Welder", active: false)

    assert_includes Fabricator.active, active
    assert_not_includes Fabricator.active, inactive
  end

  test "cannot be deleted when fabrication logs exist" do
    fabricator = Fabricator.create!(name: "Logged Welder")
    create_fabrication_log!(fabricator: fabricator)

    assert_no_difference "Fabricator.count" do
      fabricator.destroy
    end
    assert fabricator.persisted?
    assert fabricator.errors[:base].present?
  end

  private

  def create_fabrication_log!(fabricator:)
    FabricationLog.create!(
      fabricator: fabricator,
      job_process: create_job_process!,
      work_type: "PROD",
      work_date: Date.current,
      start_time: "08:00",
      end_time: "10:00"
    )
  end

  def create_job_process!
    job = Job.create!(job_no: "FAB-#{SecureRandom.hex(4)}", customer_name: "Laser Link", due_date: Date.current, status: "Draft")
    job.job_processes.create!(process_code: "PROFAB", status: "Draft")
  end
end
