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

ActiveRecord::Schema[8.0].define(version: 2025_03_14_173949) do
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

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "language", default: "en"
    t.string "audio_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "note_chats_count", default: 0, null: false
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "summaries", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.string "format", default: "bullet_point", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_summaries_on_note_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bible_chat_conversations_count", default: 0, null: false
    t.integer "notes_count", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bible_chat_conversations", "users"
  add_foreign_key "bible_chat_messages", "bible_chat_conversations"
  add_foreign_key "bible_chat_messages", "users"
  add_foreign_key "note_chats", "notes"
  add_foreign_key "note_chats", "users"
  add_foreign_key "notes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "summaries", "notes"
end
