class CreateJobProcesses < ActiveRecord::Migration[8.1]
  def change
    create_table :job_processes do |t|
      t.references :job, null: false, foreign_key: true
      t.string :process_code
      t.string :process_name
      t.string :status
      t.datetime :posted_at
      t.datetime :completed_at
      t.text :hold_reason
      t.text :operator_note

      t.timestamps
    end
  end
end
