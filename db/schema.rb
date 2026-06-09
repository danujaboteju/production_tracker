# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_05_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "customer"
    t.integer "cycle_time"
    t.integer "duration"
    t.text "job"
    t.date "prod_day", null: false
    t.text "program"
    t.text "reason"
    t.integer "sheets"
    t.text "time_between"
    t.datetime "ts", precision: 0, null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["customer"], name: "idx_events_customer"
    t.index ["job"], name: "idx_events_job"
    t.index ["prod_day", "type"], name: "idx_events_prod_type"
    t.index ["prod_day"], name: "index_events_on_prod_day"
    t.index ["program", "ts"], name: "idx_events_program", order: { ts: :desc }
    t.index ["program", "ts"], name: "index_events_on_program_and_ts"
    t.index ["ts"], name: "idx_events_ts", order: :desc
    t.index ["ts"], name: "index_events_on_ts"
    t.index ["type"], name: "index_events_on_type"
  end

  create_table "fabrication_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_time"
    t.bigint "fabricator_id", null: false
    t.bigint "job_process_id"
    t.text "note"
    t.string "other_job_name"
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.string "work_type", null: false
    t.index ["fabricator_id"], name: "index_fabrication_logs_on_fabricator_id"
    t.index ["job_process_id"], name: "index_fabrication_logs_on_job_process_id"
    t.index ["work_date"], name: "index_fabrication_logs_on_work_date"
    t.index ["work_type"], name: "index_fabrication_logs_on_work_type"
  end

  create_table "fabricator_operations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "fabricator_id", null: false
    t.string "operation_code", null: false
    t.datetime "updated_at", null: false
    t.index ["fabricator_id", "operation_code"], name: "idx_on_fabricator_id_operation_code_e0d04315dc", unique: true
    t.index ["fabricator_id"], name: "index_fabricator_operations_on_fabricator_id"
    t.index ["operation_code"], name: "index_fabricator_operations_on_operation_code"
  end

  create_table "fabricators", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_fabricators_on_lower_name", unique: true
  end

  create_table "job_processes", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "hold_reason"
    t.bigint "job_id", null: false
    t.text "operator_note"
    t.datetime "posted_at"
    t.string "process_code"
    t.string "process_name"
    t.integer "stage_no"
    t.datetime "started_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["job_id", "stage_no"], name: "index_job_processes_on_job_id_and_stage_no"
    t.index ["job_id"], name: "index_job_processes_on_job_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_name"
    t.date "due_date"
    t.string "job_no"
    t.text "notes"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "runs", force: :cascade do |t|
    t.decimal "avg_cycle_time", precision: 10, scale: 2, null: false
    t.text "customer", null: false
    t.timestamptz "first_prod_day"
    t.text "job", null: false
    t.timestamptz "last_prod_day"
    t.text "program", null: false
    t.integer "total_sheets", null: false
    t.index ["customer", "job"], name: "idx_runs_customer_job"
    t.index ["program"], name: "idx_runs_program"
    t.unique_constraint ["customer", "job", "program"], name: "runs_customer_job_program_key"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "fabrication_logs", "fabricators"
  add_foreign_key "fabrication_logs", "job_processes"
  add_foreign_key "fabricator_operations", "fabricators"
  add_foreign_key "job_processes", "jobs"
end
