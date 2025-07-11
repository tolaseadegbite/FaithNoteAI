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

ActiveRecord::Schema[8.0].define(version: 2025_05_28_184704) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bible_chat_conversations", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bible_chat_messages_count", default: 0, null: false
    t.index ["user_id", "created_at"], name: "index_bible_chat_conversations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_bible_chat_conversations_on_user_id"
  end

  create_table "bible_chat_messages", force: :cascade do |t|
    t.text "content", null: false
    t.string "role", null: false
    t.boolean "processing", default: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "translation"
    t.bigint "bible_chat_conversation_id"
    t.index ["bible_chat_conversation_id", "created_at"], name: "index_messages_on_conversation_and_created_at"
    t.index ["bible_chat_conversation_id"], name: "index_bible_chat_messages_on_bible_chat_conversation_id"
    t.index ["user_id"], name: "index_bible_chat_messages_on_user_id"
  end

  create_table "bible_verses", force: :cascade do |t|
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "verse", null: false
    t.text "content", null: false
    t.string "translation", default: "KJV", null: false
    t.string "language", default: "en", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book", "chapter", "translation"], name: "index_bible_verses_on_book_and_chapter_and_translation"
    t.index ["book", "chapter", "verse", "translation", "language"], name: "index_bible_verses_on_reference_and_translation", unique: true
    t.index ["content"], name: "index_bible_verses_on_content_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["translation"], name: "index_bible_verses_on_translation"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notes_count", default: 0
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "note_chats", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "role", null: false
    t.boolean "processing", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_note_chats_on_note_id"
    t.index ["user_id"], name: "index_note_chats_on_user_id"
  end

  create_table "note_tags", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_note_tags_on_note_id"
    t.index ["tag_id"], name: "index_note_tags_on_tag_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "language", default: "en"
    t.string "audio_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "note_chats_count", default: 0, null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_notes_on_category_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "paystack_plan_code", null: false
    t.integer "amount", null: false
    t.string "interval", null: false
    t.string "currency", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["paystack_plan_code"], name: "index_plans_on_paystack_plan_code", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "paystack_plan_code"
    t.string "paystack_subscription_code"
    t.string "status"
    t.datetime "expires_at"
    t.string "paystack_customer_code"
    t.string "plan_name"
    t.string "interval"
    t.integer "amount"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "paystack_transaction_reference"
    t.string "authorization_code"
    t.string "card_type"
    t.string "last_four_digits"
    t.string "exp_month"
    t.string "exp_year"
    t.string "bank"
    t.datetime "paid_at"
    t.datetime "next_payment_date"
    t.bigint "plan_id", null: false
    t.integer "pending_plan_id"
    t.string "pending_plan_change_type"
    t.datetime "pending_plan_change_at"
    t.index ["authorization_code"], name: "index_subscriptions_on_authorization_code"
    t.index ["paystack_customer_code"], name: "index_subscriptions_on_paystack_customer_code"
    t.index ["paystack_subscription_code"], name: "index_subscriptions_on_paystack_subscription_code", unique: true
    t.index ["paystack_transaction_reference"], name: "index_subscriptions_on_paystack_transaction_reference"
    t.index ["pending_plan_id"], name: "index_subscriptions_on_pending_plan_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'pending'::character varying, 'non_renewing'::character varying, 'expired'::character varying, 'incomplete'::character varying]::text[])", name: "status_check"
  end

  create_table "summaries", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.string "format", default: "bullet_point", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_summaries_on_note_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notes_count", default: 0
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bible_chat_conversations_count", default: 0, null: false
    t.integer "notes_count", default: 0, null: false
    t.integer "categories_count", default: 0
    t.string "name"
    t.string "paystack_customer_code"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["paystack_customer_code"], name: "index_users_on_paystack_customer_code"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bible_chat_conversations", "users"
  add_foreign_key "bible_chat_messages", "bible_chat_conversations"
  add_foreign_key "bible_chat_messages", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "note_chats", "notes"
  add_foreign_key "note_chats", "users"
  add_foreign_key "note_tags", "notes"
  add_foreign_key "note_tags", "tags"
  add_foreign_key "notes", "categories"
  add_foreign_key "notes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "summaries", "notes"
  add_foreign_key "tags", "users"
end
