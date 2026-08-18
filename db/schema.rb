# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_14_184100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "merchants", force: :cascade do |t|
    t.string "api_key"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "cutoff_hour"
    t.decimal "latitude", precision: 10, scale: 6, default: "-6.2088", null: false
    t.decimal "longitude", precision: 10, scale: 6, default: "106.8456", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.string "bin_location"
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.decimal "price"
    t.string "product_name"
    t.integer "quantity"
    t.string "sku"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "buyer_name"
    t.string "buyer_phone"
    t.datetime "created_at", null: false
    t.bigint "merchant_id", null: false
    t.string "order_number"
    t.datetime "same_day_cutoff_at"
    t.text "shipping_address"
    t.string "status"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_orders_on_merchant_id"
  end

  create_table "returns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "merchant_id", null: false
    t.bigint "order_id", null: false
    t.string "reason"
    t.datetime "resolved_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_returns_on_merchant_id"
    t.index ["order_id"], name: "index_returns_on_order_id"
  end

  create_table "shipping_labels", force: :cascade do |t|
    t.string "awb_number"
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.string "pdf_url"
    t.integer "reprint_count"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_shipping_labels_on_order_id"
  end

  create_table "staff_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "merchant_id", null: false
    t.string "name"
    t.string "password_digest"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_staff_users_on_merchant_id"
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "merchants"
  add_foreign_key "returns", "merchants"
  add_foreign_key "returns", "orders"
  add_foreign_key "shipping_labels", "orders"
  add_foreign_key "staff_users", "merchants"
end
