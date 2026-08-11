class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :order_number
      t.string :status
      t.datetime :same_day_cutoff_at
      t.string :buyer_name
      t.string :buyer_phone
      t.text :shipping_address
      t.decimal :total_amount

      t.timestamps
    end
  end
end
