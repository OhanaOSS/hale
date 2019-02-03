# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_09_214107) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "comment_replies", force: :cascade do |t|
    t.text "body", null: false
    t.text "edit"
    t.bigint "comment_id"
    t.bigint "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_replies_on_comment_id"
    t.index ["member_id"], name: "index_comment_replies_on_member_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.text "edit"
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.integer "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
  end

  create_table "event_rsvps", force: :cascade do |t|
    t.integer "party_size", default: 1, null: false
    t.integer "rsvp", default: 0, null: false
    t.boolean "bringing_food", default: false
    t.bigint "recipe_id"
    t.string "non_recipe_description"
    t.integer "serving", default: 0
    t.bigint "member_id"
    t.text "party_companions", array: true
    t.bigint "event_id"
    t.text "rsvp_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_rsvps_on_event_id"
    t.index ["member_id"], name: "index_event_rsvps_on_member_id"
    t.index ["recipe_id"], name: "index_event_rsvps_on_recipe_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "event_start", null: false
    t.datetime "event_end"
    t.boolean "event_allday", default: false
    t.float "location", array: true
    t.boolean "potluck", default: false
    t.boolean "locked", default: false
    t.bigint "family_id"
    t.bigint "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_events_on_family_id"
    t.index ["member_id"], name: "index_events_on_member_id"
  end

  create_table "families", force: :cascade do |t|
    t.string "family_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "family_configs", force: :cascade do |t|
    t.bigint "family_id", null: false
    t.boolean "authorization_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_configs_on_family_id"
  end

  create_table "family_members", force: :cascade do |t|
    t.bigint "family_id", null: false
    t.bigint "member_id", null: false
    t.integer "user_role", default: 0
    t.datetime "authorized_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_members_on_family_id"
    t.index ["member_id"], name: "index_family_members_on_member_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.string "email"
    t.bigint "family_id"
    t.integer "sender_id"
    t.integer "recipient_id"
    t.string "token"
    t.datetime "sent_at"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_invites_on_family_id"
    t.index ["token"], name: "index_invites_on_token"
  end

  create_table "members", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: true
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "surname"
    t.json "contacts", default: "{}"
    t.json "addresses", default: "{}"
    t.integer "gender"
    t.text "bio"
    t.date "birthday"
    t.string "instagram"
    t.index ["confirmation_token"], name: "index_members_on_confirmation_token", unique: true
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_members_on_uid_and_provider", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.bigint "member_id", null: false
    t.boolean "mentioned", default: false
    t.boolean "viewed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_notifications_on_member_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.float "location", array: true
    t.text "edit"
    t.boolean "locked", default: false
    t.bigint "family_id"
    t.bigint "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_posts_on_family_id"
    t.index ["member_id"], name: "index_posts_on_member_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.integer "emotive"
    t.string "interaction_type", null: false
    t.bigint "interaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interaction_type", "interaction_id"], name: "index_reactions_on_interaction_type_and_interaction_id"
    t.index ["member_id"], name: "index_reactions_on_member_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "ingredient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipe_tags", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_recipe_tags_on_recipe_id"
    t.index ["tag_id"], name: "index_recipe_tags_on_tag_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.json "steps"
    t.text "ingredients_list", array: true
    t.text "tags_list", array: true
    t.bigint "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_recipes_on_member_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "title", null: false
    t.string "description"
    t.boolean "mature", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
