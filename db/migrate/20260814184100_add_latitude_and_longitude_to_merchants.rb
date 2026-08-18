class AddLatitudeAndLongitudeToMerchants < ActiveRecord::Migration[8.0]
  def change
    add_column :merchants, :latitude, :decimal, precision: 10, scale: 6, default: -6.2088, null: false
    add_column :merchants, :longitude, :decimal, precision: 10, scale: 6, default: 106.8456, null: false
  end
end
