class AddPasswordDigestToStaffUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :staff_users, :password_digest, :string
  end
end
