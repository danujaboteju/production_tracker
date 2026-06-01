require "test_helper"

class JobTest < ActiveSupport::TestCase
  test "release moves job into progress and starts the first stage only" do
    job = build_job_with_processes("J-100", ["PROCUT", "PENTL", "PROPB", "PROFAB"])

    assert job.release!

    processes = job.reload.ordered_job_processes
    assert_equal "In Progress", job.status
    assert_equal ["In Progress", "In Progress", "Posted", "Posted"], processes.map(&:status)
    assert processes.all? { |process| process.posted_at.present? }
  end

  test "completing part of a stage does not start the next stage" do
    job = build_job_with_processes("J-101", ["PROCUT", "PENTL", "PROPB"])
    job.release!

    first_process = job.ordered_job_processes.first
    first_process.update!(status: "Completed", completed_at: Time.current)
    job.advance_after_process_completed!

    assert_equal ["Completed", "In Progress", "Posted"], job.reload.ordered_job_processes.map(&:status)
    assert_equal "In Progress", job.status
  end

  test "completing a stage starts every process in the next posted stage" do
    job = build_job_with_processes("J-102", ["PROCUT", "PENTL", "PROPB", "PRORO", "PROFAB"])
    job.release!

    job.ordered_job_processes.select { |process| process.stage_no == 2 }.each do |process|
      process.update!(status: "Completed", completed_at: Time.current)
    end
    job.advance_after_process_completed!

    assert_equal ["Completed", "Completed", "In Progress", "In Progress", "Posted"], job.reload.ordered_job_processes.map(&:status)
    assert_equal "In Progress", job.status
  end

  test "completing the final process completes the job" do
    job = build_job_with_processes("J-103", ["PROCUT"])
    job.release!

    process = job.ordered_job_processes.first
    process.update!(status: "Completed", completed_at: Time.current)
    job.advance_after_process_completed!

    assert_equal "Completed", job.reload.status
  end

  test "refresh keeps posted jobs in progress" do
    job = Job.create!(
      job_no: "J-104",
      customer_name: "Laser Link",
      due_date: Date.current,
      status: "In Progress"
    )
    job.job_processes.create!(
      process_code: "PROCUT",
      process_name: "Miter Saw Cutting",
      status: "Posted",
      posted_at: Time.current
    )

    job.refresh_progress_status!

    assert_equal "In Progress", job.reload.status
  end

  private

  def build_job_with_processes(job_no, process_codes)
    job = Job.create!(
      job_no: job_no,
      customer_name: "Laser Link",
      due_date: Date.current,
      status: "Draft"
    )

    process_codes.each do |code|
      job.job_processes.create!(
        process_code: code,
        process_name: JobProcess.process_name_for(code),
        status: "Draft"
      )
    end

    job
  end
end
