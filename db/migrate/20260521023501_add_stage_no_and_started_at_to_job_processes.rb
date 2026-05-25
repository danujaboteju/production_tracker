class AddStageNoAndStartedAtToJobProcesses < ActiveRecord::Migration[7.1]
  def change
    add_column :job_processes, :stage_no, :integer
    add_column :job_processes, :started_at, :datetime

    add_index :job_processes, [:job_id, :stage_no]
  end
end