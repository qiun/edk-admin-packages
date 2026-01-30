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

ActiveRecord::Schema[8.1].define(version: 2026_01_30_071423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "area_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.bigint "leader_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_area_groups_on_edition_id"
    t.index ["leader_id"], name: "index_area_groups_on_leader_id"
  end

  create_table "donations", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.string "email", null: false
    t.string "first_name"
    t.boolean "gift_pending", default: false, null: false
    t.string "last_name"
    t.string "locker_address"
    t.string "locker_city"
    t.string "locker_code"
    t.string "locker_name"
    t.string "locker_post_code"
    t.string "payment_id"
    t.string "payment_status", default: "pending"
    t.string "payment_transaction_id"
    t.string "phone"
    t.integer "quantity", null: false
    t.boolean "terms_accepted", default: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "want_gift", default: false
    t.index ["edition_id"], name: "index_donations_on_edition_id"
    t.index ["payment_id"], name: "index_donations_on_payment_id"
    t.index ["payment_status"], name: "index_donations_on_payment_status"
  end

  create_table "editions", force: :cascade do |t|
    t.boolean "check_donation_inventory", default: false, null: false
    t.datetime "created_at", null: false
    t.decimal "default_price", precision: 8, scale: 2, default: "30.0"
    t.decimal "donor_brick_price", precision: 8, scale: 2, default: "50.0"
    t.decimal "donor_shipping_cost", precision: 8, scale: 2, default: "20.0", null: false
    t.boolean "is_active", default: false
    t.string "name", null: false
    t.boolean "ordering_locked", default: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["is_active"], name: "index_editions_on_is_active"
    t.index ["status"], name: "index_editions_on_status"
    t.index ["year"], name: "index_editions_on_year"
  end

  create_table "inventories", force: :cascade do |t|
    t.integer "available", default: 0
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.integer "reserved", default: 0
    t.integer "returned", default: 0
    t.integer "shipped", default: 0
    t.integer "total_stock", default: 0
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_inventories_on_edition_id", unique: true
  end

  create_table "inventory_moves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "inventory_id", null: false
    t.string "move_type", null: false
    t.text "notes"
    t.integer "quantity", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_inventory_moves_on_created_by_id"
    t.index ["inventory_id"], name: "index_inventory_moves_on_inventory_id"
    t.index ["reference_type", "reference_id"], name: "index_inventory_moves_on_reference_type_and_reference_id"
  end

  create_table "leader_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "custom_price", precision: 8, scale: 2
    t.bigint "edition_id", null: false
    t.boolean "ordering_locked", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_leader_settings_on_edition_id"
    t.index ["user_id", "edition_id"], name: "index_leader_settings_on_user_id_and_edition_id", unique: true
    t.index ["user_id"], name: "index_leader_settings_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edition_id"
    t.text "message"
    t.jsonb "metadata", default: {}
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["edition_id"], name: "index_notifications_on_edition_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "area_group_id"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.string "locker_address"
    t.string "locker_city"
    t.string "locker_code"
    t.string "locker_name"
    t.string "locker_post_code"
    t.decimal "price_per_unit", precision: 8, scale: 2
    t.integer "quantity", null: false
    t.string "status", default: "pending"
    t.decimal "total_amount", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["area_group_id"], name: "index_orders_on_area_group_id"
    t.index ["edition_id", "status"], name: "index_orders_on_edition_id_and_status"
    t.index ["edition_id"], name: "index_orders_on_edition_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "returns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.string "locker_code"
    t.string "locker_name"
    t.text "notes"
    t.integer "quantity", null: false
    t.datetime "received_at"
    t.string "status", default: "requested"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_returns_on_edition_id"
    t.index ["status"], name: "index_returns_on_status"
    t.index ["user_id"], name: "index_returns_on_user_id"
  end

  create_table "sales_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.text "notes"
    t.integer "quantity_sold", null: false
    t.datetime "reported_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_sales_reports_on_edition_id"
    t.index ["user_id"], name: "index_sales_reports_on_user_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.decimal "amount_due", precision: 10, scale: 2
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.bigint "edition_id", null: false
    t.decimal "price_per_unit", precision: 8, scale: 2
    t.datetime "settled_at"
    t.string "status", default: "pending"
    t.integer "total_returned", default: 0
    t.integer "total_sent", default: 0
    t.integer "total_sold", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_settlements_on_edition_id"
    t.index ["status"], name: "index_settlements_on_status"
    t.index ["user_id", "edition_id"], name: "index_settlements_on_user_id_and_edition_id", unique: true
    t.index ["user_id"], name: "index_settlements_on_user_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "apaczka_order_id"
    t.json "apaczka_response"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.bigint "donation_id"
    t.binary "label_pdf"
    t.bigint "order_id"
    t.datetime "shipped_at"
    t.string "status", default: "pending"
    t.string "tracking_url"
    t.datetime "updated_at", null: false
    t.string "waybill_number"
    t.index ["apaczka_order_id"], name: "index_shipments_on_apaczka_order_id"
    t.index ["donation_id"], name: "index_shipments_on_donation_id"
    t.index ["order_id"], name: "index_shipments_on_order_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["waybill_number"], name: "index_shipments_on_waybill_number"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "leader", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_users_on_created_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "area_groups", "editions"
  add_foreign_key "area_groups", "users", column: "leader_id"
  add_foreign_key "donations", "editions"
  add_foreign_key "inventories", "editions"
  add_foreign_key "inventory_moves", "inventories"
  add_foreign_key "inventory_moves", "users", column: "created_by_id"
  add_foreign_key "leader_settings", "editions"
  add_foreign_key "leader_settings", "users"
  add_foreign_key "notifications", "editions"
  add_foreign_key "notifications", "users"
  add_foreign_key "orders", "area_groups"
  add_foreign_key "orders", "editions"
  add_foreign_key "orders", "users"
  add_foreign_key "returns", "editions"
  add_foreign_key "returns", "users"
  add_foreign_key "sales_reports", "editions"
  add_foreign_key "sales_reports", "users"
  add_foreign_key "settlements", "editions"
  add_foreign_key "settlements", "users"
  add_foreign_key "shipments", "donations"
  add_foreign_key "shipments", "orders"
  add_foreign_key "users", "users", column: "created_by_id"
end
