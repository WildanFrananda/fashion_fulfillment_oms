class CreateShippingLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_labels do |t|
      t.references :order, null: false, foreign_key: true
      t.string :awb_number
      t.string :pdf_url
      t.integer :reprint_count

      t.timestamps
    end
  end
end
