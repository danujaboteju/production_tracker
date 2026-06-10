class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_index :users, :username, unique: true unless index_exists?(:users, :username)
  end
end