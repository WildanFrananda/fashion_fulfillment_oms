class AddPerformanceIndexesToTables < ActiveRecord::Migration[8.1]
  def change
    add_index :merchants, :api_key, unique: true
    add_index :merchants, :code, unique: true

    add_index :orders, [ :merchant_id, :order_number ], unique: true
    add_index :orders, [ :merchant_id, :same_day_cutoff_at ]

    add_index :shipping_labels, :awb_number, unique: true
  end
end
