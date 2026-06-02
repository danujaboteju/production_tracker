class AllowEndTimeToBeBlankOnFabricationLogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :fabrication_logs, :end_time, true
  end
end
