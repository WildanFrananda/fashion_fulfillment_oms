class CreateStaffUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_users do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name
      t.string :email
      t.string :role

      t.timestamps
    end
  end
end
