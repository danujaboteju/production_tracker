class CreateFabricatorOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :fabricator_operations do |t|
      t.references :fabricator, null: false, foreign_key: true
      t.string :operation_code, null: false

      t.timestamps
    end

    add_index :fabricator_operations, [:fabricator_id, :operation_code], unique: true
    add_index :fabricator_operations, :operation_code
  end
end
