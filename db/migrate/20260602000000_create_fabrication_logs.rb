class CreateFabricationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :fabrication_logs do |t|
      t.references :job_process, null: false, foreign_key: true
      t.date :work_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :fabricator_name, null: false
      t.text :note

      t.timestamps
    end
  end
end
