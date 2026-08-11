class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name
      t.string :code
      t.string :api_key
      t.integer :cutoff_hour

      t.timestamps
    end
  end
end
