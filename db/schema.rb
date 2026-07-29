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

ActiveRecord::Schema[8.1].define(version: 2026_07_30_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "academy_setting_events", force: :cascade do |t|
    t.bigint "academy_setting_id", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["academy_setting_id", "created_at"], name: "idx_on_academy_setting_id_created_at_3f745e7160"
    t.index ["academy_setting_id"], name: "index_academy_setting_events_on_academy_setting_id"
    t.index ["actor_id"], name: "index_academy_setting_events_on_actor_id"
  end

  create_table "academy_settings", force: :cascade do |t|
    t.integer "absence_after_minutes", default: 15, null: false
    t.string "academy_name", default: "Quran Academy", null: false
    t.string "address_line_1"
    t.string "address_line_2"
    t.boolean "allow_manual_attendance_adjustment", default: true, null: false
    t.boolean "allow_student_self_cancellation", default: true, null: false
    t.boolean "allow_teacher_self_cancellation", default: false, null: false
    t.boolean "attendance_notifications_enabled", default: true, null: false
    t.string "billing_currency", default: "EGP", null: false
    t.string "billing_cycle", default: "monthly", null: false
    t.string "city"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "country_code", default: "EG", null: false
    t.datetime "created_at", null: false
    t.time "day_ends_at", default: "2000-01-01 22:00:00", null: false
    t.time "day_starts_at", default: "2000-01-01 08:00:00", null: false
    t.integer "default_lesson_duration_minutes", default: 30, null: false
    t.decimal "default_lesson_price", precision: 12, scale: 2, default: "0.0", null: false
    t.string "default_locale", default: "ar", null: false
    t.string "default_teacher_compensation_type", default: "per_lesson", null: false
    t.decimal "default_teacher_rate", precision: 12, scale: 2, default: "0.0", null: false
    t.string "default_time_zone", default: "Cairo", null: false
    t.text "description"
    t.boolean "email_notifications_enabled", default: true, null: false
    t.integer "late_cancellation_window_hours", default: 2, null: false
    t.string "legal_name"
    t.integer "lesson_duration_step_minutes", default: 15, null: false
    t.integer "lesson_reminder_hours_before", default: 24, null: false
    t.boolean "lesson_reminders_enabled", default: true, null: false
    t.integer "maximum_booking_window_days", default: 90, null: false
    t.integer "maximum_lesson_duration_minutes", default: 120, null: false
    t.integer "minimum_booking_notice_hours", default: 2, null: false
    t.integer "minimum_lesson_duration_minutes", default: 15, null: false
    t.boolean "payment_notifications_enabled", default: false, null: false
    t.string "payroll_currency", default: "EGP", null: false
    t.string "payroll_period", default: "monthly", null: false
    t.string "postal_code"
    t.integer "reschedule_notice_hours", default: 12, null: false
    t.integer "second_lesson_reminder_minutes_before", default: 60, null: false
    t.string "short_name"
    t.string "singleton_key", default: "current", null: false
    t.boolean "sms_notifications_enabled", default: false, null: false
    t.string "state_or_region"
    t.integer "student_cancellation_notice_hours", default: 12, null: false
    t.integer "student_late_after_minutes", default: 5, null: false
    t.string "supported_locales", default: ["ar", "en"], null: false, array: true
    t.integer "teacher_cancellation_notice_hours", default: 12, null: false
    t.integer "teacher_late_after_minutes", default: 5, null: false
    t.string "teaching_languages", default: ["ar", "en"], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "website_url"
    t.boolean "whatsapp_notifications_enabled", default: false, null: false
    t.string "whatsapp_number"
    t.string "working_days", default: ["saturday", "sunday", "monday", "tuesday", "wednesday", "thursday"], null: false, array: true
    t.index ["singleton_key"], name: "index_academy_settings_on_singleton_key", unique: true
    t.index ["updated_by_id"], name: "index_academy_settings_on_updated_by_id"
    t.check_constraint "day_starts_at < day_ends_at", name: "academy_settings_operating_hours"
    t.check_constraint "default_teacher_rate >= 0::numeric AND default_lesson_price >= 0::numeric", name: "academy_settings_nonnegative_money"
    t.check_constraint "minimum_lesson_duration_minutes <= default_lesson_duration_minutes AND default_lesson_duration_minutes <= maximum_lesson_duration_minutes", name: "academy_settings_lesson_duration_order"
    t.check_constraint "singleton_key::text = 'current'::text", name: "academy_settings_singleton"
  end

  create_table "guardian_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "guardian_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_guardian_events_on_actor_id"
    t.index ["event_type"], name: "index_guardian_events_on_event_type"
    t.index ["guardian_id", "created_at"], name: "index_guardian_events_on_guardian_id_and_created_at"
    t.index ["guardian_id"], name: "index_guardian_events_on_guardian_id"
  end

  create_table "guardians", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "email"
    t.string "full_name", null: false
    t.string "gender", default: "unspecified", null: false
    t.text "internal_notes"
    t.string "occupation"
    t.string "phone_number"
    t.string "preferred_contact_method", default: "email", null: false
    t.string "preferred_language", default: "ar", null: false
    t.string "public_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "whatsapp_number"
    t.index "lower((email)::text)", name: "index_guardians_on_lower_email"
    t.index ["created_by_id"], name: "index_guardians_on_created_by_id"
    t.index ["preferred_contact_method"], name: "index_guardians_on_preferred_contact_method"
    t.index ["public_id"], name: "index_guardians_on_public_id", unique: true
    t.index ["status"], name: "index_guardians_on_status"
    t.index ["updated_by_id"], name: "index_guardians_on_updated_by_id"
  end

  create_table "student_guardianship_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "student_guardianship_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_student_guardianship_events_on_actor_id"
    t.index ["event_type"], name: "index_student_guardianship_events_on_event_type"
    t.index ["student_guardianship_id", "created_at"], name: "idx_on_student_guardianship_id_created_at_f373284ad4"
    t.index ["student_guardianship_id"], name: "index_student_guardianship_events_on_student_guardianship_id"
  end

  create_table "student_guardianships", force: :cascade do |t|
    t.boolean "can_make_academic_decisions", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "custom_relationship"
    t.boolean "emergency_contact", default: false, null: false
    t.date "ends_on"
    t.bigint "guardian_id", null: false
    t.boolean "legal_guardian", default: false, null: false
    t.text "notes"
    t.boolean "primary_contact", default: false, null: false
    t.boolean "receives_academic_updates", default: true, null: false
    t.boolean "receives_billing_updates", default: false, null: false
    t.string "relationship_type", null: false
    t.date "starts_on"
    t.string "status", default: "active", null: false
    t.bigint "student_profile_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_student_guardianships_on_created_by_id"
    t.index ["guardian_id"], name: "index_student_guardianships_on_guardian_id"
    t.index ["status"], name: "index_student_guardianships_on_status"
    t.index ["student_profile_id", "guardian_id", "relationship_type"], name: "idx_unique_active_guardianship", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["student_profile_id", "guardian_id", "status"], name: "idx_guardianships_student_guardian_status"
    t.index ["student_profile_id", "primary_contact"], name: "idx_guardianships_primary_lookup"
    t.index ["student_profile_id"], name: "idx_one_active_primary_guardian", unique: true, where: "(primary_contact AND ((status)::text = 'active'::text))"
    t.index ["student_profile_id"], name: "index_student_guardianships_on_student_profile_id"
    t.index ["updated_by_id"], name: "index_student_guardianships_on_updated_by_id"
    t.check_constraint "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on", name: "student_guardianships_date_order"
  end

  create_table "student_profile_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "student_profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_student_profile_events_on_actor_id"
    t.index ["event_type"], name: "index_student_profile_events_on_event_type"
    t.index ["student_profile_id", "created_at"], name: "idx_on_student_profile_id_created_at_a3b6b9db2b"
    t.index ["student_profile_id"], name: "index_student_profile_events_on_student_profile_id"
  end

  create_table "student_profiles", force: :cascade do |t|
    t.string "city"
    t.string "country_of_residence"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "current_quran_level", default: "beginner", null: false
    t.date "date_of_birth"
    t.string "display_name"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "gender", default: "unspecified", null: false
    t.text "internal_notes"
    t.date "joined_on"
    t.text "learning_goals"
    t.text "learning_notes"
    t.string "learning_status", default: "prospective", null: false
    t.date "left_on"
    t.text "medical_notes"
    t.string "memorization_level", default: "none", null: false
    t.integer "memorized_juz_count"
    t.text "memorized_surahs"
    t.string "nationality"
    t.string "native_language"
    t.string "phone_number"
    t.string "preferred_contact_method", default: "email", null: false
    t.string "preferred_interface_locale", default: "en", null: false
    t.string "preferred_learning_language"
    t.string "profile_status", default: "draft", null: false
    t.string "public_id", null: false
    t.string "reading_level", default: "not_started", null: false
    t.text "safeguarding_notes"
    t.text "special_learning_needs"
    t.string "student_type", default: "adult", null: false
    t.string "tajweed_level", default: "none", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.string "whatsapp_number"
    t.index ["created_by_id"], name: "index_student_profiles_on_created_by_id"
    t.index ["date_of_birth"], name: "index_student_profiles_on_date_of_birth"
    t.index ["joined_on"], name: "index_student_profiles_on_joined_on"
    t.index ["learning_status"], name: "index_student_profiles_on_learning_status"
    t.index ["preferred_learning_language"], name: "index_student_profiles_on_preferred_learning_language"
    t.index ["profile_status"], name: "index_student_profiles_on_profile_status"
    t.index ["public_id"], name: "index_student_profiles_on_public_id", unique: true
    t.index ["student_type"], name: "index_student_profiles_on_student_type"
    t.index ["updated_by_id"], name: "index_student_profiles_on_updated_by_id"
    t.index ["user_id"], name: "index_student_profiles_on_user_id", unique: true
    t.check_constraint "left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on", name: "student_profiles_date_order"
    t.check_constraint "memorized_juz_count IS NULL OR memorized_juz_count >= 0 AND memorized_juz_count <= 30", name: "student_profiles_juz_range"
  end

  create_table "teacher_profile_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "teacher_profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_teacher_profile_events_on_actor_id"
    t.index ["event_type"], name: "index_teacher_profile_events_on_event_type"
    t.index ["teacher_profile_id", "created_at"], name: "idx_on_teacher_profile_id_created_at_258e33ce7c"
    t.index ["teacher_profile_id"], name: "index_teacher_profile_events_on_teacher_profile_id"
  end

  create_table "teacher_profiles", force: :cascade do |t|
    t.text "bio"
    t.string "city"
    t.string "compensation_currency", default: "EGP", null: false
    t.string "compensation_unit", default: "per_lesson", null: false
    t.string "country_of_residence"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "date_of_birth"
    t.decimal "default_lesson_rate", precision: 12, scale: 2, default: "0.0", null: false
    t.string "display_name"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "employment_status", default: "candidate", null: false
    t.string "engagement_type", default: "contractor", null: false
    t.string "gender", default: "unspecified", null: false
    t.string "highest_qualification"
    t.text "ijazah_details"
    t.string "ijazah_status", default: "none", null: false
    t.text "internal_notes"
    t.date "joined_on"
    t.date "left_on"
    t.string "nationality"
    t.string "phone_number"
    t.string "profile_status", default: "draft", null: false
    t.string "public_id", null: false
    t.text "qualification_details"
    t.integer "quran_teaching_experience_years", default: 0, null: false
    t.string "student_age_groups", default: [], null: false, array: true
    t.string "tajweed_qualification"
    t.string "teaching_languages", default: [], null: false, array: true
    t.string "teaching_specializations", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.string "whatsapp_number"
    t.integer "years_of_teaching_experience", default: 0, null: false
    t.index ["created_by_id"], name: "index_teacher_profiles_on_created_by_id"
    t.index ["employment_status"], name: "index_teacher_profiles_on_employment_status"
    t.index ["engagement_type"], name: "index_teacher_profiles_on_engagement_type"
    t.index ["joined_on"], name: "index_teacher_profiles_on_joined_on"
    t.index ["profile_status"], name: "index_teacher_profiles_on_profile_status"
    t.index ["public_id"], name: "index_teacher_profiles_on_public_id", unique: true
    t.index ["student_age_groups"], name: "index_teacher_profiles_on_student_age_groups", using: :gin
    t.index ["teaching_languages"], name: "index_teacher_profiles_on_teaching_languages", using: :gin
    t.index ["teaching_specializations"], name: "index_teacher_profiles_on_teaching_specializations", using: :gin
    t.index ["updated_by_id"], name: "index_teacher_profiles_on_updated_by_id"
    t.index ["user_id"], name: "index_teacher_profiles_on_user_id", unique: true
    t.check_constraint "default_lesson_rate >= 0::numeric", name: "teacher_profiles_rate_nonnegative"
    t.check_constraint "left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on", name: "teacher_profiles_date_order"
    t.check_constraint "quran_teaching_experience_years >= 0", name: "teacher_profiles_quran_experience_nonnegative"
    t.check_constraint "years_of_teaching_experience >= 0", name: "teacher_profiles_experience_nonnegative"
  end

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
    t.check_constraint "preferred_locale::text = ANY (ARRAY['ar'::character varying::text, 'en'::character varying::text])", name: "users_preferred_locale"
    t.check_constraint "session_version >= 0", name: "users_session_version_nonnegative"
  end

  add_foreign_key "academy_setting_events", "academy_settings", on_delete: :restrict
  add_foreign_key "academy_setting_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "academy_settings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "guardian_events", "guardians", on_delete: :restrict
  add_foreign_key "guardian_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "guardians", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "guardians", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "student_guardianship_events", "student_guardianships", on_delete: :restrict
  add_foreign_key "student_guardianship_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "student_guardianships", "guardians", on_delete: :restrict
  add_foreign_key "student_guardianships", "student_profiles", on_delete: :restrict
  add_foreign_key "student_guardianships", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "student_guardianships", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "student_profile_events", "student_profiles", on_delete: :restrict
  add_foreign_key "student_profile_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "student_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "student_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "student_profiles", "users", on_delete: :restrict
  add_foreign_key "teacher_profile_events", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_profile_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "target_user_id", on_delete: :restrict
  add_foreign_key "users", "users", column: "approved_by_id", on_delete: :nullify
end
