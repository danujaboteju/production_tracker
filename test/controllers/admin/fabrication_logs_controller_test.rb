require "test_helper"

module Admin
  class FabricationLogsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @fabricator = Fabricator.create!(name: "Controller Welder")
        @fabricator.fabricator_operations.create!(operation_code: "PROFAB")
      @job = Job.create!(job_no: "CTL-#{SecureRandom.hex(4)}", customer_name: "Laser Link", due_date: Date.current, status: "Draft")
      @job_process = @job.job_processes.create!(process_code: "PROFAB", status: "Draft")
    end

    test "job-created logs use a Fabricator record and PROD work type" do
      assert_difference "FabricationLog.count", 1 do
        post admin_job_job_process_fabrication_logs_path(@job, @job_process), params: {
          fabrication_log: {
            work_date: Date.current,
            start_time: "08:00",
            end_time: "10:00",
            fabricator_id: @fabricator.id,
            note: "Fit up"
          }
        }
      end

      log = @job_process.fabrication_logs.last
      assert_redirected_to admin_job_path(@job)
      assert_equal @fabricator, log.fabricator
      assert_equal "PROD", log.work_type
      assert_equal @job_process, log.job_process
    end

    test "existing job log update behaviour still works for open logs" do
      log = create_log!(end_time: nil)

      patch admin_job_job_process_fabrication_log_path(@job, @job_process, log), params: {
        fabrication_log: {
          work_date: log.work_date,
          start_time: "08:00",
          end_time: "11:30",
          fabricator_id: @fabricator.id,
          note: "Closed out"
        }
      }

      assert_redirected_to admin_job_path(@job)
      log.reload
      assert_equal "Closed out", log.note
      assert_equal "PROD", log.work_type
      assert_equal 3.5, log.duration_hours.to_f
    end

    test "existing job log delete behaviour still works" do
      log = create_log!

      assert_difference "FabricationLog.count", -1 do
        delete admin_job_job_process_fabrication_log_path(@job, @job_process, log)
      end

      assert_redirected_to admin_job_path(@job)
    end

    private

    def create_log!(end_time: "10:00")
      @job_process.fabrication_logs.create!(
        fabricator: @fabricator,
        work_type: "PROD",
        work_date: Date.current,
        start_time: "08:00",
        end_time: end_time
      )
    end
  end
end
