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

ActiveRecord::Schema[8.1].define(version: 2026_07_29_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "user_account_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "target_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id", "created_at"], name: "index_user_account_events_on_actor_id_and_created_at"
    t.index ["actor_id"], name: "index_user_account_events_on_actor_id"
    t.index ["event_type"], name: "index_user_account_events_on_event_type"
    t.index ["target_user_id", "created_at"], name: "index_user_account_events_on_target_user_id_and_created_at"
    t.index ["target_user_id"], name: "index_user_account_events_on_target_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "preferred_locale", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 1, null: false
    t.integer "session_version", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "time_zone", default: "Cairo", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_users_on_approved_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status", "role", "created_at"], name: "index_users_on_status_and_role_and_created_at"
    t.index ["status"], name: "index_users_on_status"
    t.check_constraint "preferred_locale::text = ANY (ARRAY['ar'::character varying, 'en'::character varying]::text[])", name: "users_preferred_locale"
    t.check_constraint "session_version >= 0", name: "users_session_version_nonnegative"
  end

  add_foreign_key "user_account_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "target_user_id", on_delete: :restrict
  add_foreign_key "users", "users", column: "approved_by_id", on_delete: :nullify
end
