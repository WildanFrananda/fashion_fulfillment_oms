class AddBinLocationToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :bin_location, :string
  end
end
