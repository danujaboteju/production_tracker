class CreateFabricatorsAndUpdateFabricationLogs < ActiveRecord::Migration[8.1]
  class MigrationFabricator < ActiveRecord::Base
    self.table_name = "fabricators"
  end

  class MigrationFabricationLog < ActiveRecord::Base
    self.table_name = "fabrication_logs"
  end

  def up
    create_table :fabricators do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :fabricators, "LOWER(name)", unique: true, name: "index_fabricators_on_lower_name"

    add_reference :fabrication_logs, :fabricator, foreign_key: true
    add_column :fabrication_logs, :work_type, :string
    add_column :fabrication_logs, :other_job_name, :string
    add_index :fabrication_logs, :work_type
    add_index :fabrication_logs, :work_date

    backfill_fabricators

    change_column_null :fabrication_logs, :fabricator_id, false
    change_column_null :fabrication_logs, :work_type, false
    change_column_null :fabrication_logs, :job_process_id, true

    remove_column :fabrication_logs, :fabricator_name
  end

  def down
    add_column :fabrication_logs, :fabricator_name, :string

    MigrationFabricationLog.reset_column_information

    MigrationFabricationLog.find_each do |log|
      fabricator_name = MigrationFabricator.where(id: log.fabricator_id).pick(:name)
      log.update_columns(fabricator_name: fabricator_name.presence || "Unknown Fabricator")
    end

    change_column_null :fabrication_logs, :fabricator_name, false
    change_column_null :fabrication_logs, :job_process_id, false

    remove_index :fabrication_logs, :work_date
    remove_index :fabrication_logs, :work_type
    remove_column :fabrication_logs, :other_job_name
    remove_column :fabrication_logs, :work_type
    remove_reference :fabrication_logs, :fabricator, foreign_key: true

    drop_table :fabricators
  end

  private

  def backfill_fabricators
    MigrationFabricator.reset_column_information
    MigrationFabricationLog.reset_column_information

    fabricators_by_normalized_name = {}

    MigrationFabricationLog.distinct.pluck(:fabricator_name).each do |fabricator_name|
      trimmed_name = fabricator_name.to_s.strip
      trimmed_name = "Unknown Fabricator" if trimmed_name.blank?
      normalized_name = trimmed_name.downcase

      fabricators_by_normalized_name[normalized_name] ||= MigrationFabricator.create!(name: trimmed_name)
    end

    MigrationFabricationLog.find_each do |log|
      trimmed_name = log.fabricator_name.to_s.strip
      trimmed_name = "Unknown Fabricator" if trimmed_name.blank?
      fabricator = fabricators_by_normalized_name.fetch(trimmed_name.downcase)

      log.update_columns(
        fabricator_id: fabricator.id,
        work_type: "PROD"
      )
    end
  end
end
