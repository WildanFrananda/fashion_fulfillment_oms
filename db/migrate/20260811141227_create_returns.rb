class CreateReturns < ActiveRecord::Migration[8.1]
  def change
    create_table :returns do |t|
      t.references :merchant, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :reason
      t.string :status
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
