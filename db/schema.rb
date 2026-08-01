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

ActiveRecord::Schema[8.1].define(version: 2026_08_01_100000) do
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
    t.integer "left_early_threshold_minutes", default: 5, null: false
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
    t.integer "teacher_check_in_closes_minutes_after", default: 30, null: false
    t.integer "teacher_check_in_opens_minutes_before", default: 15, null: false
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

  create_table "course_offering_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "course_offering_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_course_offering_events_on_actor_id"
    t.index ["course_offering_id", "created_at"], name: "idx_on_course_offering_id_created_at_f05a4c6e71"
    t.index ["course_offering_id"], name: "index_course_offering_events_on_course_offering_id"
    t.index ["event_type"], name: "index_course_offering_events_on_event_type"
  end

  create_table "course_offerings", force: :cascade do |t|
    t.boolean "accepts_new_enrollments", default: false, null: false
    t.integer "capacity"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "default_lesson_duration_minutes", null: false
    t.string "delivery_mode", default: "online", null: false
    t.text "description_ar"
    t.text "description_en"
    t.date "enrollment_closes_on"
    t.date "enrollment_opens_on"
    t.integer "intended_lessons_per_week", null: false
    t.text "internal_notes"
    t.string "learning_language", null: false
    t.boolean "placement_required", default: false, null: false
    t.date "planned_end_on"
    t.date "planned_start_on"
    t.bigint "program_id", null: false
    t.string "public_id", null: false
    t.string "status", default: "draft", null: false
    t.string "target_age_groups", default: [], null: false, array: true
    t.string "title_ar", null: false
    t.string "title_en", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index "lower((code)::text)", name: "index_course_offerings_on_lower_code", unique: true
    t.index ["accepts_new_enrollments"], name: "index_course_offerings_on_accepts_new_enrollments"
    t.index ["created_by_id"], name: "index_course_offerings_on_created_by_id"
    t.index ["delivery_mode"], name: "index_course_offerings_on_delivery_mode"
    t.index ["enrollment_closes_on"], name: "index_course_offerings_on_enrollment_closes_on"
    t.index ["learning_language"], name: "index_course_offerings_on_learning_language"
    t.index ["planned_start_on"], name: "index_course_offerings_on_planned_start_on"
    t.index ["program_id"], name: "index_course_offerings_on_program_id"
    t.index ["public_id"], name: "index_course_offerings_on_public_id", unique: true
    t.index ["status"], name: "index_course_offerings_on_status"
    t.index ["target_age_groups"], name: "index_course_offerings_on_target_age_groups", using: :gin
    t.index ["updated_by_id"], name: "index_course_offerings_on_updated_by_id"
    t.check_constraint "capacity IS NULL OR capacity > 0", name: "offerings_capacity_positive"
    t.check_constraint "default_lesson_duration_minutes > 0", name: "offerings_duration_positive"
    t.check_constraint "enrollment_closes_on IS NULL OR enrollment_opens_on IS NULL OR enrollment_closes_on >= enrollment_opens_on", name: "offerings_enrollment_date_order"
    t.check_constraint "intended_lessons_per_week > 0", name: "offerings_frequency_positive"
    t.check_constraint "planned_end_on IS NULL OR planned_start_on IS NULL OR planned_end_on >= planned_start_on", name: "offerings_planned_date_order"
  end

  create_table "enrollment_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_enrollment_events_on_actor_id"
    t.index ["enrollment_id", "created_at"], name: "index_enrollment_events_on_enrollment_id_and_created_at"
    t.index ["enrollment_id"], name: "index_enrollment_events_on_enrollment_id"
    t.index ["event_type"], name: "index_enrollment_events_on_event_type"
  end

  create_table "enrollments", force: :cascade do |t|
    t.text "administrator_notes"
    t.string "application_source", default: "administrator", null: false
    t.date "applied_on", null: false
    t.bigint "approved_by_id"
    t.date "approved_on"
    t.date "cancelled_on"
    t.date "completed_on"
    t.bigint "course_offering_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "ended_by_id"
    t.date "ended_on"
    t.text "exit_notes"
    t.string "exit_reason"
    t.date "paused_on"
    t.date "placement_completed_on"
    t.string "placement_method"
    t.text "placement_notes"
    t.string "placement_status", default: "not_required", null: false
    t.text "preferred_schedule_notes"
    t.string "public_id", null: false
    t.date "rejected_on"
    t.date "resumed_on"
    t.date "started_on"
    t.string "starting_memorization_level"
    t.integer "starting_memorized_juz_count"
    t.string "starting_quran_level"
    t.string "starting_reading_level"
    t.string "starting_tajweed_level"
    t.string "status", default: "pending", null: false
    t.text "student_goals_snapshot"
    t.bigint "student_profile_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.date "withdrawn_on"
    t.index ["application_source"], name: "index_enrollments_on_application_source"
    t.index ["applied_on"], name: "index_enrollments_on_applied_on"
    t.index ["approved_by_id"], name: "index_enrollments_on_approved_by_id"
    t.index ["course_offering_id", "status"], name: "index_enrollments_on_course_offering_id_and_status"
    t.index ["course_offering_id"], name: "index_enrollments_on_course_offering_id"
    t.index ["created_by_id"], name: "index_enrollments_on_created_by_id"
    t.index ["ended_by_id"], name: "index_enrollments_on_ended_by_id"
    t.index ["placement_status"], name: "index_enrollments_on_placement_status"
    t.index ["public_id"], name: "index_enrollments_on_public_id", unique: true
    t.index ["started_on"], name: "index_enrollments_on_started_on"
    t.index ["status"], name: "index_enrollments_on_status"
    t.index ["student_profile_id", "course_offering_id"], name: "index_enrollments_unique_membership", unique: true
    t.index ["student_profile_id", "created_at"], name: "index_enrollments_on_student_profile_id_and_created_at"
    t.index ["student_profile_id"], name: "index_enrollments_on_student_profile_id"
    t.index ["updated_by_id"], name: "index_enrollments_on_updated_by_id"
    t.check_constraint "starting_memorized_juz_count IS NULL OR starting_memorized_juz_count >= 0 AND starting_memorized_juz_count <= 30", name: "enrollments_starting_juz_range"
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

  create_table "lesson_attendance_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "lesson_attendance_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_lesson_attendance_events_on_actor_id"
    t.index ["event_type"], name: "index_lesson_attendance_events_on_event_type"
    t.index ["lesson_attendance_id", "created_at"], name: "idx_attendance_events_record_created"
    t.index ["lesson_attendance_id"], name: "index_lesson_attendance_events_on_lesson_attendance_id"
  end

  create_table "lesson_attendances", force: :cascade do |t|
    t.string "adjustment_reason"
    t.datetime "arrival_at"
    t.datetime "created_at", null: false
    t.datetime "departure_at"
    t.string "excuse_reason"
    t.datetime "last_adjusted_at"
    t.bigint "last_adjusted_by_id"
    t.integer "lock_version", default: 0, null: false
    t.integer "minutes_late", default: 0, null: false
    t.text "notes"
    t.string "public_id", null: false
    t.datetime "recorded_at"
    t.bigint "recorded_by_id"
    t.bigint "scheduled_lesson_enrollment_id", null: false
    t.bigint "scheduled_lesson_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["last_adjusted_by_id"], name: "index_lesson_attendances_on_last_adjusted_by_id"
    t.index ["public_id"], name: "index_lesson_attendances_on_public_id", unique: true
    t.index ["recorded_by_id"], name: "index_lesson_attendances_on_recorded_by_id"
    t.index ["scheduled_lesson_enrollment_id"], name: "idx_lesson_attendance_participant_unique", unique: true
    t.index ["scheduled_lesson_enrollment_id"], name: "index_lesson_attendances_on_scheduled_lesson_enrollment_id"
    t.index ["scheduled_lesson_id"], name: "index_lesson_attendances_on_scheduled_lesson_id"
    t.index ["status", "arrival_at"], name: "index_lesson_attendances_on_status_and_arrival_at"
    t.check_constraint "departure_at IS NULL OR arrival_at IS NULL OR departure_at >= arrival_at", name: "lesson_attendances_time_order"
    t.check_constraint "minutes_late >= 0", name: "lesson_attendances_nonnegative_lateness"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'present'::character varying, 'late'::character varying, 'absent'::character varying, 'excused_absence'::character varying, 'left_early'::character varying, 'lesson_cancelled'::character varying, 'not_applicable'::character varying]::text[])", name: "lesson_attendances_status"
  end

  create_table "program_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "program_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_program_events_on_actor_id"
    t.index ["event_type"], name: "index_program_events_on_event_type"
    t.index ["program_id", "created_at"], name: "index_program_events_on_program_id_and_created_at"
    t.index ["program_id"], name: "index_program_events_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.boolean "allows_adult_students", default: true, null: false
    t.boolean "allows_minor_students", default: true, null: false
    t.string "category", null: false
    t.string "code", null: false
    t.string "completion_level", default: "intermediate", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "default_learning_language", null: false
    t.integer "default_lesson_duration_minutes", default: 30, null: false
    t.text "description_ar"
    t.text "description_en"
    t.integer "display_order", default: 0, null: false
    t.string "entry_level", default: "not_started", null: false
    t.integer "estimated_duration_weeks"
    t.text "internal_notes"
    t.string "name_ar", null: false
    t.string "name_en", null: false
    t.string "public_id", null: false
    t.integer "recommended_lessons_per_week", default: 2, null: false
    t.boolean "requires_placement", default: false, null: false
    t.text "short_description_ar"
    t.text "short_description_en"
    t.string "status", default: "draft", null: false
    t.string "supported_learning_languages", default: [], null: false, array: true
    t.string "target_age_groups", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index "lower((code)::text)", name: "index_programs_on_lower_code", unique: true
    t.index ["category"], name: "index_programs_on_category"
    t.index ["created_by_id"], name: "index_programs_on_created_by_id"
    t.index ["display_order"], name: "index_programs_on_display_order"
    t.index ["public_id"], name: "index_programs_on_public_id", unique: true
    t.index ["status"], name: "index_programs_on_status"
    t.index ["supported_learning_languages"], name: "index_programs_on_supported_learning_languages", using: :gin
    t.index ["target_age_groups"], name: "index_programs_on_target_age_groups", using: :gin
    t.index ["updated_by_id"], name: "index_programs_on_updated_by_id"
    t.check_constraint "default_lesson_duration_minutes > 0", name: "programs_duration_positive"
    t.check_constraint "estimated_duration_weeks IS NULL OR estimated_duration_weeks >= 0", name: "programs_duration_weeks_nonnegative"
    t.check_constraint "recommended_lessons_per_week > 0", name: "programs_frequency_positive"
  end

  create_table "scheduled_lesson_enrollments", force: :cascade do |t|
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.string "participation_status", default: "expected", null: false
    t.bigint "scheduled_lesson_id", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_scheduled_lesson_enrollments_on_added_by_id"
    t.index ["enrollment_id"], name: "index_scheduled_lesson_enrollments_on_enrollment_id"
    t.index ["participation_status"], name: "index_scheduled_lesson_enrollments_on_participation_status"
    t.index ["scheduled_lesson_id", "enrollment_id"], name: "index_scheduled_lesson_enrollments_unique", unique: true
    t.index ["scheduled_lesson_id"], name: "index_scheduled_lesson_enrollments_on_scheduled_lesson_id"
  end

  create_table "scheduled_lesson_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "scheduled_lesson_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_scheduled_lesson_events_on_actor_id"
    t.index ["event_type"], name: "index_scheduled_lesson_events_on_event_type"
    t.index ["scheduled_lesson_id", "created_at"], name: "idx_on_scheduled_lesson_id_created_at_ee34dd8901"
    t.index ["scheduled_lesson_id"], name: "index_scheduled_lesson_events_on_scheduled_lesson_id"
  end

  create_table "scheduled_lessons", force: :cascade do |t|
    t.string "academy_time_zone", default: "Cairo", null: false
    t.datetime "attendance_locked_at"
    t.bigint "attendance_locked_by_id"
    t.datetime "attendance_opened_at"
    t.datetime "attendance_reopened_at"
    t.bigint "attendance_reopened_by_id"
    t.string "attendance_status", default: "not_opened", null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.datetime "completed_at"
    t.text "completion_notes"
    t.bigint "course_offering_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "delivery_mode", default: "online", null: false
    t.datetime "ended_at"
    t.datetime "ends_at", null: false
    t.string "location_name"
    t.integer "lock_version", default: 0, null: false
    t.string "online_meeting_url"
    t.text "operation_notes"
    t.string "public_id", null: false
    t.string "scheduling_source", default: "manual", null: false
    t.datetime "started_at"
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.string "teacher_attendance_status", default: "not_checked_in", null: false
    t.datetime "teacher_checked_in_at"
    t.bigint "teacher_profile_id", null: false
    t.string "title_ar", null: false
    t.string "title_en", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["attendance_locked_by_id"], name: "index_scheduled_lessons_on_attendance_locked_by_id"
    t.index ["attendance_reopened_by_id"], name: "index_scheduled_lessons_on_attendance_reopened_by_id"
    t.index ["attendance_status", "starts_at"], name: "index_scheduled_lessons_on_attendance_status_and_starts_at"
    t.index ["cancelled_by_id"], name: "index_scheduled_lessons_on_cancelled_by_id"
    t.index ["course_offering_id", "starts_at"], name: "index_scheduled_lessons_on_course_offering_id_and_starts_at"
    t.index ["course_offering_id"], name: "index_scheduled_lessons_on_course_offering_id"
    t.index ["created_by_id"], name: "index_scheduled_lessons_on_created_by_id"
    t.index ["public_id"], name: "index_scheduled_lessons_on_public_id", unique: true
    t.index ["status", "starts_at"], name: "index_scheduled_lessons_on_status_and_starts_at"
    t.index ["teacher_profile_id", "starts_at", "ends_at"], name: "idx_on_teacher_profile_id_starts_at_ends_at_69d19f2e3b"
    t.index ["teacher_profile_id"], name: "index_scheduled_lessons_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_scheduled_lessons_on_updated_by_id"
    t.check_constraint "attendance_status::text = ANY (ARRAY['not_opened'::character varying, 'open'::character varying, 'locked'::character varying, 'reopened'::character varying]::text[])", name: "scheduled_lessons_attendance_status"
    t.check_constraint "ends_at > starts_at", name: "scheduled_lesson_time_order"
    t.check_constraint "teacher_attendance_status::text = ANY (ARRAY['not_checked_in'::character varying, 'on_time'::character varying, 'late'::character varying, 'absent'::character varying, 'administrator_override'::character varying]::text[])", name: "scheduled_lessons_teacher_attendance_status"
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

  create_table "teacher_availabilities", force: :cascade do |t|
    t.string "availability_type", default: "teaching", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "effective_from", null: false
    t.date "effective_until"
    t.time "ends_at_local", null: false
    t.text "notes"
    t.string "public_id", null: false
    t.time "starts_at_local", null: false
    t.string "status", default: "active", null: false
    t.bigint "teacher_profile_id", null: false
    t.string "time_zone", default: "Cairo", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "weekday", null: false
    t.index ["created_by_id"], name: "index_teacher_availabilities_on_created_by_id"
    t.index ["public_id"], name: "index_teacher_availabilities_on_public_id", unique: true
    t.index ["teacher_profile_id", "weekday", "status"], name: "idx_on_teacher_profile_id_weekday_status_afa2ad9ee9"
    t.index ["teacher_profile_id"], name: "index_teacher_availabilities_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_teacher_availabilities_on_updated_by_id"
    t.check_constraint "effective_until IS NULL OR effective_until >= effective_from", name: "teacher_availability_date_order"
    t.check_constraint "ends_at_local > starts_at_local", name: "teacher_availability_time_order"
  end

  create_table "teacher_availability_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "teacher_availability_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_teacher_availability_events_on_actor_id"
    t.index ["event_type"], name: "index_teacher_availability_events_on_event_type"
    t.index ["teacher_availability_id", "created_at"], name: "idx_on_teacher_availability_id_created_at_d13f9d240b"
    t.index ["teacher_availability_id"], name: "index_teacher_availability_events_on_teacher_availability_id"
  end

  create_table "teacher_availability_exception_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "teacher_availability_exception_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_teacher_availability_exception_events_on_actor_id"
    t.index ["event_type"], name: "index_teacher_availability_exception_events_on_event_type"
    t.index ["teacher_availability_exception_id", "created_at"], name: "idx_on_teacher_availability_exception_id_created_at_0c3df20b0c"
    t.index ["teacher_availability_exception_id"], name: "idx_on_teacher_availability_exception_id_49df9153c1"
  end

  create_table "teacher_availability_exceptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.time "ends_at_local"
    t.date "exception_date", null: false
    t.string "exception_type", null: false
    t.string "public_id", null: false
    t.string "reason"
    t.time "starts_at_local"
    t.string "status", default: "active", null: false
    t.bigint "teacher_profile_id", null: false
    t.string "time_zone", default: "Cairo", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_teacher_availability_exceptions_on_created_by_id"
    t.index ["public_id"], name: "index_teacher_availability_exceptions_on_public_id", unique: true
    t.index ["teacher_profile_id", "exception_date", "status"], name: "idx_on_teacher_profile_id_exception_date_status_5559a35a4e"
    t.index ["teacher_profile_id"], name: "index_teacher_availability_exceptions_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_teacher_availability_exceptions_on_updated_by_id"
    t.check_constraint "starts_at_local IS NULL AND ends_at_local IS NULL OR starts_at_local IS NOT NULL AND ends_at_local IS NOT NULL AND ends_at_local > starts_at_local", name: "teacher_exception_time_order"
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
  add_foreign_key "course_offering_events", "course_offerings", on_delete: :restrict
  add_foreign_key "course_offering_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "course_offerings", "programs", on_delete: :restrict
  add_foreign_key "course_offerings", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "course_offerings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "enrollment_events", "enrollments", on_delete: :restrict
  add_foreign_key "enrollment_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "enrollments", "course_offerings", on_delete: :restrict
  add_foreign_key "enrollments", "student_profiles", on_delete: :restrict
  add_foreign_key "enrollments", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "ended_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "guardian_events", "guardians", on_delete: :restrict
  add_foreign_key "guardian_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "guardians", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "guardians", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "lesson_attendance_events", "lesson_attendances", on_delete: :restrict
  add_foreign_key "lesson_attendance_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "lesson_attendances", "scheduled_lesson_enrollments", on_delete: :restrict
  add_foreign_key "lesson_attendances", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "lesson_attendances", "users", column: "last_adjusted_by_id", on_delete: :nullify
  add_foreign_key "lesson_attendances", "users", column: "recorded_by_id", on_delete: :nullify
  add_foreign_key "program_events", "programs", on_delete: :restrict
  add_foreign_key "program_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "programs", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "programs", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lesson_enrollments", "enrollments", on_delete: :restrict
  add_foreign_key "scheduled_lesson_enrollments", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "scheduled_lesson_enrollments", "users", column: "added_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lesson_events", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "scheduled_lesson_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "scheduled_lessons", "course_offerings", on_delete: :restrict
  add_foreign_key "scheduled_lessons", "teacher_profiles", on_delete: :restrict
  add_foreign_key "scheduled_lessons", "users", column: "attendance_locked_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "attendance_reopened_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "cancelled_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "updated_by_id", on_delete: :nullify
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
  add_foreign_key "teacher_availabilities", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_availabilities", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "teacher_availabilities", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "teacher_availability_events", "teacher_availabilities", on_delete: :restrict
  add_foreign_key "teacher_availability_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_availability_exception_events", "teacher_availability_exceptions", on_delete: :restrict
  add_foreign_key "teacher_availability_exception_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_availability_exceptions", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_availability_exceptions", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "teacher_availability_exceptions", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "teacher_profile_events", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_profile_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "target_user_id", on_delete: :restrict
  add_foreign_key "users", "users", column: "approved_by_id", on_delete: :nullify
end
