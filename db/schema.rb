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

ActiveRecord::Schema[8.1].define(version: 2026_02_14_174339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "allocation_changes", force: :cascade do |t|
    t.bigint "changed_by_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "new_allocated"
    t.integer "new_allocated_posters"
    t.integer "new_distributed_posters"
    t.integer "new_sold"
    t.integer "previous_allocated"
    t.integer "previous_allocated_posters"
    t.integer "previous_distributed_posters"
    t.integer "previous_sold"
    t.text "reason"
    t.bigint "region_allocation_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["changed_by_id"], name: "index_allocation_changes_on_changed_by_id"
    t.index ["region_allocation_id"], name: "index_allocation_changes_on_region_allocation_id"
  end

  create_table "area_groups", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.bigint "edition_id", null: false
    t.bigint "leader_id"
    t.string "name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "voivodeship_id"
    t.index ["edition_id"], name: "index_area_groups_on_edition_id"
    t.index ["leader_id"], name: "index_area_groups_on_leader_id"
    t.index ["voivodeship_id"], name: "index_area_groups_on_voivodeship_id"
  end

  create_table "donations", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "want_gift", default: false
    t.index ["edition_id"], name: "index_donations_on_edition_id"
    t.index ["payment_id"], name: "index_donations_on_payment_id"
    t.index ["payment_status"], name: "index_donations_on_payment_status"
  end

  create_table "editions", force: :cascade do |t|
    t.boolean "check_donation_inventory", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.decimal "default_price", precision: 8, scale: 2, default: "30.0"
    t.decimal "donation_package_height", precision: 5, scale: 1, default: "64.0", null: false
    t.decimal "donation_package_length", precision: 5, scale: 1, default: "19.0", null: false
    t.decimal "donation_package_max_weight", precision: 5, scale: 2, default: "1.0", null: false
    t.decimal "donation_package_width", precision: 5, scale: 1, default: "38.0", null: false
    t.string "donation_sender_city", default: "Świebodzin", null: false
    t.string "donation_sender_email", default: "pakiety@edk.org.pl", null: false
    t.string "donation_sender_name", default: "Sklep EDK - Rafał Wojtkiewicz", null: false
    t.string "donation_sender_phone", default: "602736554", null: false
    t.string "donation_sender_post_code", default: "66-200", null: false
    t.string "donation_sender_street", default: "ul. Sobieskiego 19", null: false
    t.decimal "donor_brick_price", precision: 8, scale: 2, default: "50.0"
    t.decimal "donor_shipping_cost", precision: 8, scale: 2, default: "20.0", null: false
    t.boolean "is_active", default: false
    t.string "name", null: false
    t.decimal "order_package_height", precision: 5, scale: 1, default: "64.0", null: false
    t.decimal "order_package_length", precision: 5, scale: 1, default: "41.0", null: false
    t.decimal "order_package_max_weight", precision: 5, scale: 2, default: "30.0", null: false
    t.decimal "order_package_width", precision: 5, scale: 1, default: "38.0", null: false
    t.string "order_sender_city", default: "Świebodzin", null: false
    t.string "order_sender_email", default: "pakiety@edk.org.pl", null: false
    t.string "order_sender_name", default: "Magazyn EDK - Rafał Wojtkiewicz", null: false
    t.string "order_sender_phone", default: "602736554", null: false
    t.string "order_sender_post_code", default: "66-200", null: false
    t.string "order_sender_street", default: "ul. Konarskiego 8", null: false
    t.boolean "ordering_locked", default: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "year", null: false
    t.index ["is_active"], name: "index_editions_on_is_active"
    t.index ["status"], name: "index_editions_on_status"
    t.index ["year"], name: "index_editions_on_year"
  end

  create_table "inventories", force: :cascade do |t|
    t.integer "available", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.integer "reserved", default: 0
    t.integer "returned", default: 0
    t.integer "shipped", default: 0
    t.integer "total_stock", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["edition_id"], name: "index_inventories_on_edition_id", unique: true
  end

  create_table "inventory_moves", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "inventory_id", null: false
    t.string "move_type", null: false
    t.text "notes"
    t.integer "quantity", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_by_id"], name: "index_inventory_moves_on_created_by_id"
    t.index ["inventory_id"], name: "index_inventory_moves_on_inventory_id"
    t.index ["reference_type", "reference_id"], name: "index_inventory_moves_on_reference_type_and_reference_id"
  end

  create_table "leader_settings", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.decimal "custom_price", precision: 8, scale: 2
    t.bigint "edition_id", null: false
    t.boolean "ordering_locked", default: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_leader_settings_on_edition_id"
    t.index ["user_id", "edition_id"], name: "index_leader_settings_on_user_id_and_edition_id", unique: true
    t.index ["user_id"], name: "index_leader_settings_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id"
    t.text "message"
    t.jsonb "metadata", default: {}
    t.string "notification_type", null: false
    t.datetime "read_at", precision: nil
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.index ["edition_id"], name: "index_notifications_on_edition_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "area_group_id"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.string "locker_address"
    t.string "locker_city"
    t.string "locker_code"
    t.string "locker_name"
    t.string "locker_post_code"
    t.integer "poster_quantity", default: 0, null: false
    t.decimal "price_per_unit", precision: 8, scale: 2
    t.integer "quantity", null: false
    t.string "status", default: "pending"
    t.decimal "total_amount", precision: 10, scale: 2
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.index ["area_group_id"], name: "index_orders_on_area_group_id"
    t.index ["edition_id", "status"], name: "index_orders_on_edition_id_and_status"
    t.index ["edition_id"], name: "index_orders_on_edition_id"
    t.index ["poster_quantity"], name: "index_orders_on_poster_quantity"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "region_allocations", force: :cascade do |t|
    t.integer "allocated_posters", default: 0, null: false
    t.integer "allocated_quantity", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "created_by_id", null: false
    t.integer "distributed_posters", default: 0, null: false
    t.bigint "edition_id", null: false
    t.bigint "region_id", null: false
    t.integer "sold_quantity", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["allocated_posters"], name: "index_region_allocations_on_allocated_posters"
    t.index ["created_by_id"], name: "index_region_allocations_on_created_by_id"
    t.index ["distributed_posters"], name: "index_region_allocations_on_distributed_posters"
    t.index ["edition_id"], name: "index_region_allocations_on_edition_id"
    t.index ["region_id", "edition_id"], name: "index_region_allocations_on_region_edition", unique: true
    t.index ["region_id"], name: "index_region_allocations_on_region_id"
  end

  create_table "region_transfers", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.bigint "from_region_id", null: false
    t.integer "poster_quantity", default: 0, null: false
    t.integer "quantity", null: false
    t.text "reason"
    t.string "status", default: "pending", null: false
    t.bigint "to_region_id", null: false
    t.datetime "transferred_at", precision: nil
    t.bigint "transferred_by_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["edition_id"], name: "index_region_transfers_on_edition_id"
    t.index ["from_region_id"], name: "index_region_transfers_on_from_region_id"
    t.index ["poster_quantity"], name: "index_region_transfers_on_poster_quantity"
    t.index ["to_region_id"], name: "index_region_transfers_on_to_region_id"
    t.index ["transferred_by_id"], name: "index_region_transfers_on_transferred_by_id"
  end

  create_table "regional_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.text "notes"
    t.date "payment_date", null: false
    t.bigint "recorded_by_id", null: false
    t.bigint "region_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["edition_id"], name: "index_regional_payments_on_edition_id"
    t.index ["recorded_by_id"], name: "index_regional_payments_on_recorded_by_id"
    t.index ["region_id"], name: "index_regional_payments_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.bigint "area_group_id", null: false
    t.string "contact_person"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "created_by_id", null: false
    t.bigint "edition_id", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["area_group_id", "edition_id", "name"], name: "index_regions_on_area_edition_name", unique: true
    t.index ["area_group_id"], name: "index_regions_on_area_group_id"
    t.index ["created_by_id"], name: "index_regions_on_created_by_id"
    t.index ["edition_id"], name: "index_regions_on_edition_id"
  end

  create_table "returns", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.string "locker_code"
    t.string "locker_name"
    t.text "notes"
    t.integer "quantity", null: false
    t.datetime "received_at", precision: nil
    t.string "status", default: "requested"
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_returns_on_edition_id"
    t.index ["status"], name: "index_returns_on_status"
    t.index ["user_id"], name: "index_returns_on_user_id"
  end

  create_table "sales_reports", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.text "notes"
    t.integer "quantity_sold", null: false
    t.datetime "reported_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_sales_reports_on_edition_id"
    t.index ["user_id"], name: "index_sales_reports_on_user_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.decimal "amount_due", precision: 10, scale: 2
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "edition_id", null: false
    t.decimal "price_per_unit", precision: 8, scale: 2
    t.datetime "settled_at", precision: nil
    t.string "status", default: "pending"
    t.integer "total_returned", default: 0
    t.integer "total_sent", default: 0
    t.integer "total_sold", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.index ["edition_id"], name: "index_settlements_on_edition_id"
    t.index ["status"], name: "index_settlements_on_status"
    t.index ["user_id", "edition_id"], name: "index_settlements_on_user_id_and_edition_id", unique: true
    t.index ["user_id"], name: "index_settlements_on_user_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "apaczka_order_id"
    t.json "apaczka_response"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "delivered_at", precision: nil
    t.bigint "donation_id"
    t.binary "label_pdf"
    t.bigint "order_id"
    t.datetime "shipped_at", precision: nil
    t.string "status", default: "pending"
    t.string "tracking_url"
    t.datetime "updated_at", precision: nil, null: false
    t.string "waybill_number"
    t.index ["apaczka_order_id"], name: "index_shipments_on_apaczka_order_id"
    t.index ["donation_id"], name: "index_shipments_on_donation_id"
    t.index ["order_id"], name: "index_shipments_on_order_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["waybill_number"], name: "index_shipments_on_waybill_number"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.string "role", default: "leader", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "voivodeship_id"
    t.index ["created_by_id"], name: "index_users_on_created_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["voivodeship_id"], name: "index_users_on_voivodeship_id"
  end

  create_table "voivodeships", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_voivodeships_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id", name: "active_storage_attachments_blob_id_fkey"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id", name: "active_storage_variant_records_blob_id_fkey"
  add_foreign_key "allocation_changes", "region_allocations", name: "allocation_changes_region_allocation_id_fkey"
  add_foreign_key "allocation_changes", "users", column: "changed_by_id", name: "allocation_changes_changed_by_id_fkey"
  add_foreign_key "area_groups", "editions", name: "area_groups_edition_id_fkey"
  add_foreign_key "area_groups", "users", column: "leader_id", name: "area_groups_leader_id_fkey"
  add_foreign_key "area_groups", "voivodeships", name: "area_groups_voivodeship_id_fkey"
  add_foreign_key "donations", "editions", name: "donations_edition_id_fkey"
  add_foreign_key "inventories", "editions", name: "inventories_edition_id_fkey"
  add_foreign_key "inventory_moves", "inventories", name: "inventory_moves_inventory_id_fkey"
  add_foreign_key "inventory_moves", "users", column: "created_by_id", name: "inventory_moves_created_by_id_fkey"
  add_foreign_key "leader_settings", "editions", name: "leader_settings_edition_id_fkey"
  add_foreign_key "leader_settings", "users", name: "leader_settings_user_id_fkey"
  add_foreign_key "notifications", "editions", name: "notifications_edition_id_fkey"
  add_foreign_key "notifications", "users", name: "notifications_user_id_fkey"
  add_foreign_key "orders", "area_groups", name: "orders_area_group_id_fkey"
  add_foreign_key "orders", "editions", name: "orders_edition_id_fkey"
  add_foreign_key "orders", "users", name: "orders_user_id_fkey"
  add_foreign_key "region_allocations", "editions", name: "region_allocations_edition_id_fkey"
  add_foreign_key "region_allocations", "regions", name: "region_allocations_region_id_fkey"
  add_foreign_key "region_allocations", "users", column: "created_by_id", name: "region_allocations_created_by_id_fkey"
  add_foreign_key "region_transfers", "editions", name: "region_transfers_edition_id_fkey"
  add_foreign_key "region_transfers", "regions", column: "from_region_id", name: "region_transfers_from_region_id_fkey"
  add_foreign_key "region_transfers", "regions", column: "to_region_id", name: "region_transfers_to_region_id_fkey"
  add_foreign_key "region_transfers", "users", column: "transferred_by_id", name: "region_transfers_transferred_by_id_fkey"
  add_foreign_key "regional_payments", "editions", name: "regional_payments_edition_id_fkey"
  add_foreign_key "regional_payments", "regions", name: "regional_payments_region_id_fkey"
  add_foreign_key "regional_payments", "users", column: "recorded_by_id", name: "regional_payments_recorded_by_id_fkey"
  add_foreign_key "regions", "area_groups", name: "regions_area_group_id_fkey"
  add_foreign_key "regions", "editions", name: "regions_edition_id_fkey"
  add_foreign_key "regions", "users", column: "created_by_id", name: "regions_created_by_id_fkey"
  add_foreign_key "returns", "editions", name: "returns_edition_id_fkey"
  add_foreign_key "returns", "users", name: "returns_user_id_fkey"
  add_foreign_key "sales_reports", "editions", name: "sales_reports_edition_id_fkey"
  add_foreign_key "sales_reports", "users", name: "sales_reports_user_id_fkey"
  add_foreign_key "settlements", "editions", name: "settlements_edition_id_fkey"
  add_foreign_key "settlements", "users", name: "settlements_user_id_fkey"
  add_foreign_key "shipments", "donations", name: "shipments_donation_id_fkey"
  add_foreign_key "shipments", "orders", name: "shipments_order_id_fkey"
  add_foreign_key "users", "users", column: "created_by_id", name: "users_created_by_id_fkey"
  add_foreign_key "users", "voivodeships", name: "users_voivodeship_id_fkey"
end
