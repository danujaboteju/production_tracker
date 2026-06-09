require "test_helper"

module Admin
  class JobsControllerTest < ActionDispatch::IntegrationTest
    test "in progress jobs are ordered by progress ascending" do
      low_progress = create_job_with_processes("ORDER-LOW", ["Posted", "Posted"])
      half_progress = create_job_with_processes("ORDER-HALF", ["Completed", "Posted"])
      complete_progress = create_job_with_processes("ORDER-FULL", ["Completed", "Completed"])

      get admin_jobs_path(status: "In Progress")

      assert_response :success
      low_index = response.body.index(low_progress.job_no)
      half_index = response.body.index(half_progress.job_no)
      complete_index = response.body.index(complete_progress.job_no)

      assert low_index.present?, "Expected #{low_progress.job_no} to be rendered"
      assert half_index.present?, "Expected #{half_progress.job_no} to be rendered"
      assert complete_index.present?, "Expected #{complete_progress.job_no} to be rendered"
      assert_operator low_index, :<, half_index
      assert_operator half_index, :<, complete_index
    end

    private

    def create_job_with_processes(job_no, process_statuses)
      job = Job.create!(
        job_no: job_no,
        customer_name: "Laser Link",
        due_date: Date.current,
        status: "In Progress"
      )

      process_statuses.each_with_index do |status, index|
        process_code = ["PROCUT", "PROPB", "PROFAB"][index]
        job.job_processes.create!(
          process_code: process_code,
          process_name: JobProcess.process_name_for(process_code),
          status: status,
          posted_at: Time.current,
          completed_at: status == "Completed" ? Time.current : nil
        )
      end

      job
    end
  end
end
