class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.string :job_no
      t.string :customer_name
      t.date :due_date
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
