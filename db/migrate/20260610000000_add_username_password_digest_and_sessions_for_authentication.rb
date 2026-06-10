class AddUsernamePasswordDigestAndSessionsForAuthentication < ActiveRecord::Migration[8.1]
  def up
    change_column_null :users, :email, true if column_exists?(:users, :email)
    change_column_default :users, :email, from: "", to: nil if column_exists?(:users, :email)

    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)

    unless column_exists?(:users, :role)
      add_column :users, :role, :string, default: "operator", null: false
    end

    change_column_default :users, :role, from: nil, to: "operator" if column_exists?(:users, :role)

    execute <<~SQL.squish
      UPDATE users
      SET role = 'operator'
      WHERE role IS NULL
        OR role = ''
        OR role NOT IN ('admin', 'manager', 'operator', 'viewer')
    SQL

    execute <<~SQL.squish
      UPDATE users
      SET username = 'user_' || id
      WHERE username IS NULL OR username = ''
    SQL

    change_column_null :users, :username, false
    change_column_null :users, :role, false

    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username" unless index_exists?(:users, "lower(username)", name: "index_users_on_lower_username")

    create_table :sessions, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
  end

  def down
    drop_table :sessions, if_exists: true

    remove_index :users, name: "index_users_on_lower_username" if index_exists?(:users, name: "index_users_on_lower_username")
    remove_column :users, :password_digest if column_exists?(:users, :password_digest)
    remove_column :users, :username if column_exists?(:users, :username)
    change_column_default :users, :role, from: "operator", to: nil if column_exists?(:users, :role)
  end
end
