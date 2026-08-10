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

ActiveRecord::Schema[8.1].define(version: 2026_08_10_101000) do
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
    t.jsonb "assessment_grade_boundaries", default: {"A" => 90, "B" => 80, "C" => 70, "D" => 60, "F" => 0, "A+" => 95, "B+" => 85}, null: false
    t.boolean "attendance_notifications_enabled", default: true, null: false
    t.string "billing_currency", default: "EGP", null: false
    t.string "billing_cycle", default: "monthly", null: false
    t.boolean "certificate_notifications_enabled", default: true, null: false
    t.boolean "certificate_whatsapp_enabled", default: false, null: false
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
    t.integer "first_late_reminder_minutes", default: 10, null: false
    t.string "invitation_delivery_mode", default: "email_only", null: false
    t.integer "invitation_expires_after_hours", default: 72, null: false
    t.boolean "invitation_notifications_enabled", default: true, null: false
    t.integer "late_cancellation_window_hours", default: 2, null: false
    t.integer "left_early_threshold_minutes", default: 5, null: false
    t.string "legal_name"
    t.integer "lesson_duration_step_minutes", default: 15, null: false
    t.integer "lesson_reminder_hours_before", default: 24, null: false
    t.integer "lesson_reminder_minutes_before", default: 30, null: false
    t.boolean "lesson_reminders_enabled", default: true, null: false
    t.boolean "lesson_report_notifications_enabled", default: true, null: false
    t.boolean "lesson_report_whatsapp_enabled", default: true, null: false
    t.integer "maximum_booking_window_days", default: 90, null: false
    t.integer "maximum_lesson_duration_minutes", default: 120, null: false
    t.integer "minimum_booking_notice_hours", default: 2, null: false
    t.integer "minimum_lesson_duration_minutes", default: 15, null: false
    t.boolean "payment_notifications_enabled", default: false, null: false
    t.string "payroll_currency", default: "EGP", null: false
    t.string "payroll_period", default: "monthly", null: false
    t.string "postal_code"
    t.integer "reschedule_notice_hours", default: 12, null: false
    t.integer "second_late_reminder_minutes", default: 20, null: false
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
    t.check_constraint "invitation_delivery_mode::text = ANY (ARRAY['email_only'::character varying::text, 'whatsapp_only'::character varying::text, 'email_and_whatsapp'::character varying::text])", name: "academy_settings_invitation_delivery_mode"
    t.check_constraint "invitation_expires_after_hours >= 1 AND invitation_expires_after_hours <= 8760", name: "academy_invitation_expiry_range"
    t.check_constraint "lesson_reminder_minutes_before >= 0 AND lesson_reminder_minutes_before <= 1440 AND first_late_reminder_minutes >= 0 AND first_late_reminder_minutes <= 1440 AND second_late_reminder_minutes >= 0 AND second_late_reminder_minutes <= 1440", name: "academy_notification_reminder_ranges"
    t.check_constraint "minimum_lesson_duration_minutes <= default_lesson_duration_minutes AND default_lesson_duration_minutes <= maximum_lesson_duration_minutes", name: "academy_settings_lesson_duration_order"
    t.check_constraint "singleton_key::text = 'current'::text", name: "academy_settings_singleton"
  end

  create_table "account_invitation_events", force: :cascade do |t|
    t.bigint "account_invitation_id", null: false
    t.bigint "actor_id"
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.index ["account_invitation_id", "created_at"], name: "idx_invitation_events_history"
    t.index ["account_invitation_id"], name: "index_account_invitation_events_on_account_invitation_id"
    t.index ["actor_id"], name: "index_account_invitation_events_on_actor_id"
  end

  create_table "account_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.string "accepted_ip"
    t.string "accepted_user_agent", limit: 500
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_sent_at"
    t.integer "lock_version", default: 0, null: false
    t.string "public_id", null: false
    t.integer "resent_count", default: 0, null: false
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_by_id"], name: "index_account_invitations_on_created_by_id"
    t.index ["public_id"], name: "index_account_invitations_on_public_id", unique: true
    t.index ["status", "expires_at"], name: "index_account_invitations_on_status_and_expires_at"
    t.index ["token_digest"], name: "index_account_invitations_on_token_digest", unique: true
    t.index ["user_id"], name: "index_account_invitations_on_user_id", unique: true
    t.check_constraint "resent_count >= 0", name: "invitation_resent_count_nonnegative"
  end

  create_table "assessment_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.integer "display_order", default: 0, null: false
    t.string "name_ar", null: false
    t.string "name_en", null: false
    t.string "public_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["active", "display_order"], name: "index_assessment_categories_on_active_and_display_order"
    t.index ["code"], name: "index_assessment_categories_on_code", unique: true
    t.index ["created_by_id"], name: "index_assessment_categories_on_created_by_id"
    t.index ["public_id"], name: "index_assessment_categories_on_public_id", unique: true
    t.index ["updated_by_id"], name: "index_assessment_categories_on_updated_by_id"
  end

  create_table "assessment_rubric_items", force: :cascade do |t|
    t.bigint "assessment_category_id", null: false
    t.bigint "assessment_template_id", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", default: 0, null: false
    t.decimal "maximum_score", precision: 7, scale: 2, default: "100.0", null: false
    t.string "name_ar", null: false
    t.string "name_en", null: false
    t.boolean "required", default: true, null: false
    t.string "scoring_type", default: "numeric", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 7, scale: 2, default: "1.0", null: false
    t.index ["assessment_category_id"], name: "index_assessment_rubric_items_on_assessment_category_id"
    t.index ["assessment_template_id", "display_order"], name: "idx_rubrics_template_order"
    t.index ["assessment_template_id"], name: "index_assessment_rubric_items_on_assessment_template_id"
    t.check_constraint "maximum_score > 0::numeric AND weight > 0::numeric", name: "rubric_positive_values"
    t.check_constraint "scoring_type::text = ANY (ARRAY['numeric'::character varying::text, 'rating'::character varying::text])", name: "rubric_scoring_type"
  end

  create_table "assessment_scores", force: :cascade do |t|
    t.bigint "assessment_rubric_item_id", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.decimal "numeric_score", precision: 7, scale: 2
    t.string "rating"
    t.bigint "student_assessment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_rubric_item_id"], name: "index_assessment_scores_on_assessment_rubric_item_id"
    t.index ["student_assessment_id", "assessment_rubric_item_id"], name: "idx_unique_rubric_score", unique: true
    t.index ["student_assessment_id"], name: "index_assessment_scores_on_student_assessment_id"
    t.check_constraint "numeric_score IS NULL OR numeric_score >= 0::numeric", name: "assessment_scores_nonnegative"
  end

  create_table "assessment_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.string "name_ar", null: false
    t.string "name_en", null: false
    t.string "public_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["created_by_id"], name: "index_assessment_templates_on_created_by_id"
    t.index ["public_id"], name: "index_assessment_templates_on_public_id", unique: true
    t.index ["status", "display_order"], name: "index_assessment_templates_on_status_and_display_order"
    t.index ["updated_by_id"], name: "index_assessment_templates_on_updated_by_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text, 'archived'::character varying::text])", name: "assessment_template_status"
  end

  create_table "certificate_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.bigint "certificate_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.index ["actor_id"], name: "index_certificate_events_on_actor_id"
    t.index ["certificate_id", "created_at"], name: "idx_certificate_events_history"
    t.index ["certificate_id"], name: "index_certificate_events_on_certificate_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.string "certificate_type", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id"
    t.bigint "exam_session_id"
    t.date "issued_on", null: false
    t.bigint "issuer_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.text "notes"
    t.string "public_id", null: false
    t.string "qr_placeholder"
    t.bigint "student_profile_id", null: false
    t.datetime "updated_at", null: false
    t.string "verification_code", null: false
    t.index ["enrollment_id"], name: "index_certificates_on_enrollment_id"
    t.index ["exam_session_id"], name: "index_certificates_on_exam_session_id"
    t.index ["issuer_id"], name: "index_certificates_on_issuer_id"
    t.index ["public_id"], name: "index_certificates_on_public_id", unique: true
    t.index ["student_profile_id", "issued_on"], name: "index_certificates_on_student_profile_id_and_issued_on"
    t.index ["student_profile_id"], name: "index_certificates_on_student_profile_id"
    t.index ["verification_code"], name: "index_certificates_on_verification_code", unique: true
    t.check_constraint "certificate_type::text = ANY (ARRAY['program_completion'::character varying::text, 'exam_completion'::character varying::text, 'ijazah'::character varying::text])", name: "certificate_type"
  end

  create_table "communication_log_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.bigint "communication_log_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_communication_log_events_on_actor_id"
    t.index ["communication_log_id", "created_at"], name: "idx_on_communication_log_id_created_at_16ee263b65"
    t.index ["communication_log_id"], name: "index_communication_log_events_on_communication_log_id"
    t.index ["event_type"], name: "index_communication_log_events_on_event_type"
  end

  create_table "communication_logs", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.string "channel", null: false
    t.bigint "confirmed_by_id"
    t.datetime "confirmed_sent_at"
    t.datetime "created_at", null: false
    t.text "external_url"
    t.string "failure_reason"
    t.bigint "guardian_id"
    t.bigint "lesson_report_id"
    t.bigint "lesson_student_report_id"
    t.text "message_snapshot", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "opened_at"
    t.datetime "prepared_at", null: false
    t.string "public_id", null: false
    t.string "recipient_address_masked", null: false
    t.string "recipient_locale", null: false
    t.bigint "recipient_user_id"
    t.bigint "scheduled_lesson_id"
    t.string "status", default: "prepared", null: false
    t.bigint "student_profile_id"
    t.string "subject_snapshot"
    t.string "template_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_communication_logs_on_actor_id"
    t.index ["channel", "template_type", "status"], name: "idx_on_channel_template_type_status_5d2b83df4d"
    t.index ["confirmed_by_id"], name: "index_communication_logs_on_confirmed_by_id"
    t.index ["confirmed_sent_at"], name: "index_communication_logs_on_confirmed_sent_at"
    t.index ["guardian_id"], name: "index_communication_logs_on_guardian_id"
    t.index ["lesson_report_id"], name: "index_communication_logs_on_lesson_report_id"
    t.index ["lesson_student_report_id"], name: "index_communication_logs_on_lesson_student_report_id"
    t.index ["prepared_at"], name: "index_communication_logs_on_prepared_at"
    t.index ["public_id"], name: "index_communication_logs_on_public_id", unique: true
    t.index ["recipient_user_id"], name: "index_communication_logs_on_recipient_user_id"
    t.index ["scheduled_lesson_id"], name: "index_communication_logs_on_scheduled_lesson_id"
    t.index ["student_profile_id"], name: "index_communication_logs_on_student_profile_id"
    t.check_constraint "channel::text = ANY (ARRAY['whatsapp'::character varying::text, 'email'::character varying::text])", name: "communication_logs_channel"
    t.check_constraint "status::text = ANY (ARRAY['prepared'::character varying::text, 'opened'::character varying::text, 'confirmed_sent'::character varying::text, 'cancelled'::character varying::text, 'failed'::character varying::text])", name: "communication_logs_status"
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

  create_table "enrollment_lesson_generation_issues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.bigint "enrollment_lesson_schedule_slot_id", null: false
    t.string "reason_code", null: false
    t.date "recurrence_date", null: false
    t.datetime "resolved_at"
    t.datetime "updated_at", null: false
    t.index ["enrollment_lesson_schedule_slot_id", "recurrence_date"], name: "idx_generation_issues_unique_occurrence", unique: true
    t.index ["enrollment_lesson_schedule_slot_id"], name: "idx_generation_issues_on_slot"
  end

  create_table "enrollment_lesson_schedule_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_lesson_schedule_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_enrollment_lesson_schedule_events_on_actor_id"
    t.index ["enrollment_lesson_schedule_id", "created_at"], name: "idx_schedule_events_chronological"
    t.index ["enrollment_lesson_schedule_id"], name: "idx_schedule_events_on_schedule"
  end

  create_table "enrollment_lesson_schedule_slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "enrollment_lesson_schedule_id", null: false
    t.integer "position", default: 0, null: false
    t.time "starts_at_local", null: false
    t.datetime "updated_at", null: false
    t.string "weekday", null: false
    t.index ["enrollment_lesson_schedule_id", "weekday", "starts_at_local"], name: "idx_schedule_slots_unique_weekday_time", unique: true
    t.index ["enrollment_lesson_schedule_id"], name: "idx_schedule_slots_on_schedule"
  end

  create_table "enrollment_lesson_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "ends_on"
    t.bigint "enrollment_id", null: false
    t.integer "lesson_duration_minutes", null: false
    t.string "public_id", null: false
    t.date "starts_on", null: false
    t.string "status", default: "active", null: false
    t.bigint "teacher_profile_id", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_enrollment_lesson_schedules_on_created_by_id"
    t.index ["enrollment_id", "status"], name: "index_enrollment_lesson_schedules_on_enrollment_id_and_status"
    t.index ["enrollment_id"], name: "idx_enrollment_schedules_one_active", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["enrollment_id"], name: "index_enrollment_lesson_schedules_on_enrollment_id"
    t.index ["public_id"], name: "index_enrollment_lesson_schedules_on_public_id", unique: true
    t.index ["teacher_profile_id"], name: "index_enrollment_lesson_schedules_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_enrollment_lesson_schedules_on_updated_by_id"
    t.check_constraint "ends_on IS NULL OR ends_on >= starts_on", name: "enrollment_schedule_date_order"
    t.check_constraint "lesson_duration_minutes > 0", name: "enrollment_schedule_duration_positive"
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

  create_table "exam_session_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "exam_session_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.index ["actor_id"], name: "index_exam_session_events_on_actor_id"
    t.index ["exam_session_id", "created_at"], name: "idx_exam_session_events_history"
    t.index ["exam_session_id"], name: "index_exam_session_events_on_exam_session_id"
  end

  create_table "exam_sessions", force: :cascade do |t|
    t.bigint "course_offering_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.integer "duration_minutes", null: false
    t.integer "lock_version", default: 0, null: false
    t.text "notes"
    t.bigint "program_id", null: false
    t.string "public_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.bigint "teacher_profile_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["course_offering_id"], name: "index_exam_sessions_on_course_offering_id"
    t.index ["created_by_id"], name: "index_exam_sessions_on_created_by_id"
    t.index ["program_id"], name: "index_exam_sessions_on_program_id"
    t.index ["public_id"], name: "index_exam_sessions_on_public_id", unique: true
    t.index ["status", "starts_at"], name: "index_exam_sessions_on_status_and_starts_at"
    t.index ["teacher_profile_id", "starts_at"], name: "index_exam_sessions_on_teacher_profile_id_and_starts_at"
    t.index ["teacher_profile_id"], name: "index_exam_sessions_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_exam_sessions_on_updated_by_id"
    t.check_constraint "duration_minutes >= 1 AND duration_minutes <= 480", name: "exam_duration_range"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'scheduled'::character varying::text, 'completed'::character varying::text, 'reviewed'::character varying::text, 'published'::character varying::text, 'archived'::character varying::text])", name: "exam_session_status"
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
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'present'::character varying::text, 'late'::character varying::text, 'absent'::character varying::text, 'excused_absence'::character varying::text, 'left_early'::character varying::text, 'lesson_cancelled'::character varying::text, 'not_applicable'::character varying::text])", name: "lesson_attendances_status"
  end

  create_table "lesson_report_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "lesson_report_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_lesson_report_events_on_actor_id"
    t.index ["event_type"], name: "index_lesson_report_events_on_event_type"
    t.index ["lesson_report_id", "created_at"], name: "index_lesson_report_events_on_lesson_report_id_and_created_at"
    t.index ["lesson_report_id"], name: "index_lesson_report_events_on_lesson_report_id"
  end

  create_table "lesson_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "general_homework"
    t.text "general_teacher_notes"
    t.text "lesson_summary"
    t.integer "lock_version", default: 0, null: false
    t.datetime "locked_at"
    t.bigint "locked_by_id"
    t.text "next_lesson_plan"
    t.string "overall_engagement", default: "not_assessed", null: false
    t.string "overall_progress", default: "not_assessed", null: false
    t.string "public_id", null: false
    t.datetime "reopened_at"
    t.bigint "reopened_by_id"
    t.string "reopening_reason"
    t.string "report_language", default: "ar", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.bigint "scheduled_lesson_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.bigint "submitted_by_id"
    t.bigint "teacher_profile_id", null: false
    t.text "topics_covered"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["created_by_id"], name: "index_lesson_reports_on_created_by_id"
    t.index ["locked_at"], name: "index_lesson_reports_on_locked_at"
    t.index ["locked_by_id"], name: "index_lesson_reports_on_locked_by_id"
    t.index ["public_id"], name: "index_lesson_reports_on_public_id", unique: true
    t.index ["reopened_by_id"], name: "index_lesson_reports_on_reopened_by_id"
    t.index ["reviewed_at"], name: "index_lesson_reports_on_reviewed_at"
    t.index ["reviewed_by_id"], name: "index_lesson_reports_on_reviewed_by_id"
    t.index ["scheduled_lesson_id"], name: "index_lesson_reports_on_scheduled_lesson_id", unique: true
    t.index ["status", "created_at"], name: "index_lesson_reports_on_status_and_created_at"
    t.index ["submitted_at"], name: "index_lesson_reports_on_submitted_at"
    t.index ["submitted_by_id"], name: "index_lesson_reports_on_submitted_by_id"
    t.index ["teacher_profile_id"], name: "index_lesson_reports_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_lesson_reports_on_updated_by_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'submitted'::character varying::text, 'reviewed'::character varying::text, 'locked'::character varying::text, 'reopened'::character varying::text, 'archived'::character varying::text])", name: "lesson_reports_status"
  end

  create_table "lesson_student_report_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "lesson_student_report_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_lesson_student_report_events_on_actor_id"
    t.index ["event_type"], name: "index_lesson_student_report_events_on_event_type"
    t.index ["lesson_student_report_id", "created_at"], name: "idx_on_lesson_student_report_id_created_at_91347a16e9"
    t.index ["lesson_student_report_id"], name: "index_lesson_student_report_events_on_lesson_student_report_id"
  end

  create_table "lesson_student_reports", force: :cascade do |t|
    t.text "areas_for_improvement"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "engagement_level", default: "not_assessed", null: false
    t.text "guardian_visible_notes"
    t.text "homework"
    t.bigint "lesson_report_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "memorization_from"
    t.string "memorization_material"
    t.text "memorization_notes"
    t.string "memorization_result", default: "not_assessed", null: false
    t.string "memorization_to"
    t.text "mistakes_summary"
    t.text "next_lesson_target"
    t.string "performance_level", default: "not_assessed", null: false
    t.text "private_teacher_notes"
    t.string "public_id", null: false
    t.string "reading_from"
    t.string "reading_material"
    t.text "reading_notes"
    t.string "reading_quality", default: "not_assessed", null: false
    t.string "reading_to"
    t.string "revision_material"
    t.text "revision_notes"
    t.string "revision_result", default: "not_assessed", null: false
    t.bigint "scheduled_lesson_enrollment_id", null: false
    t.string "status", default: "pending", null: false
    t.text "strengths"
    t.text "student_visible_notes"
    t.text "tajweed_observations"
    t.string "tajweed_topics", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["created_by_id"], name: "index_lesson_student_reports_on_created_by_id"
    t.index ["lesson_report_id", "scheduled_lesson_enrollment_id"], name: "idx_student_report_entry", unique: true
    t.index ["lesson_report_id"], name: "index_lesson_student_reports_on_lesson_report_id"
    t.index ["public_id"], name: "index_lesson_student_reports_on_public_id", unique: true
    t.index ["scheduled_lesson_enrollment_id"], name: "index_lesson_student_reports_on_scheduled_lesson_enrollment_id"
    t.index ["status", "engagement_level", "performance_level"], name: "idx_student_report_outcomes"
    t.index ["updated_by_id"], name: "index_lesson_student_reports_on_updated_by_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'completed'::character varying::text, 'not_applicable'::character varying::text, 'withheld'::character varying::text])", name: "lesson_student_reports_status"
  end

  create_table "notification_attempts", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.integer "attempt_number", null: false
    t.datetime "attempted_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "error_code"
    t.text "error_message"
    t.integer "http_status"
    t.bigint "notification_id", null: false
    t.string "provider", null: false
    t.string "provider_message_id"
    t.jsonb "provider_response", default: {}, null: false
    t.string "provider_status"
    t.string "recipient_address_masked", null: false
    t.string "request_fingerprint", null: false
    t.string "status", default: "sending", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notification_attempts_on_actor_id"
    t.index ["notification_id", "attempt_number"], name: "idx_notification_attempt_number", unique: true
    t.index ["notification_id"], name: "index_notification_attempts_on_notification_id"
    t.index ["provider_message_id"], name: "index_notification_attempts_on_provider_message_id"
    t.check_constraint "attempt_number > 0", name: "notification_attempt_positive"
    t.check_constraint "status::text = ANY (ARRAY['sending'::character varying::text, 'sent'::character varying::text, 'delivered'::character varying::text, 'failed'::character varying::text])", name: "notification_attempt_status"
  end

  create_table "notification_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "notification_id", null: false
    t.index ["actor_id"], name: "index_notification_events_on_actor_id"
    t.index ["notification_id", "created_at"], name: "idx_notification_event_history"
    t.index ["notification_id"], name: "index_notification_events_on_notification_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.integer "attempt_count", default: 0, null: false
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.text "delivery_payload_ciphertext"
    t.datetime "failed_at"
    t.string "failure_code"
    t.text "failure_reason"
    t.datetime "first_attempted_at"
    t.integer "http_status"
    t.string "idempotency_key"
    t.datetime "last_attempted_at"
    t.integer "lock_version", default: 0, null: false
    t.text "message_snapshot", null: false
    t.string "notification_type", null: false
    t.string "provider", null: false
    t.string "provider_message_id"
    t.jsonb "provider_response", default: {}, null: false
    t.string "provider_status"
    t.string "public_id", null: false
    t.datetime "queued_at"
    t.string "recipient_address_masked", null: false
    t.bigint "recipient_guardian_id"
    t.string "recipient_locale", null: false
    t.bigint "recipient_user_id", null: false
    t.integer "retry_count", default: 0, null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.bigint "source_id"
    t.string "source_type"
    t.string "status", default: "pending", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["channel", "status", "created_at"], name: "index_notifications_on_channel_and_status_and_created_at"
    t.index ["idempotency_key"], name: "index_notifications_on_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["provider_message_id"], name: "index_notifications_on_provider_message_id"
    t.index ["public_id"], name: "index_notifications_on_public_id", unique: true
    t.index ["recipient_guardian_id"], name: "index_notifications_on_recipient_guardian_id"
    t.index ["recipient_user_id", "created_at"], name: "index_notifications_on_recipient_user_id_and_created_at"
    t.index ["recipient_user_id"], name: "index_notifications_on_recipient_user_id"
    t.index ["scheduled_at", "status"], name: "index_notifications_on_scheduled_at_and_status"
    t.index ["source_type", "source_id"], name: "index_notifications_on_source_type_and_source_id"
    t.check_constraint "attempt_count >= 0", name: "notification_attempt_count"
    t.check_constraint "channel::text = ANY (ARRAY['email'::character varying::text, 'whatsapp'::character varying::text])", name: "notification_channel"
    t.check_constraint "provider::text = ANY (ARRAY['resend'::character varying::text, 'meta_whatsapp'::character varying::text])", name: "notification_provider"
    t.check_constraint "retry_count >= 0", name: "notification_retry_count"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'sending'::character varying::text, 'sent'::character varying::text, 'delivered'::character varying::text, 'failed'::character varying::text])", name: "notification_status"
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
    t.bigint "enrollment_lesson_schedule_slot_id"
    t.string "location_name"
    t.integer "lock_version", default: 0, null: false
    t.string "online_meeting_url"
    t.text "operation_notes"
    t.string "public_id", null: false
    t.date "recurrence_date"
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
    t.index ["enrollment_lesson_schedule_slot_id", "recurrence_date"], name: "idx_scheduled_lessons_unique_recurrence", unique: true
    t.index ["enrollment_lesson_schedule_slot_id"], name: "idx_lessons_on_recurrence_slot"
    t.index ["public_id"], name: "index_scheduled_lessons_on_public_id", unique: true
    t.index ["status", "starts_at"], name: "index_scheduled_lessons_on_status_and_starts_at"
    t.index ["teacher_profile_id", "starts_at", "ends_at"], name: "idx_on_teacher_profile_id_starts_at_ends_at_69d19f2e3b"
    t.index ["teacher_profile_id"], name: "index_scheduled_lessons_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_scheduled_lessons_on_updated_by_id"
    t.check_constraint "attendance_status::text = ANY (ARRAY['not_opened'::character varying::text, 'open'::character varying::text, 'locked'::character varying::text, 'reopened'::character varying::text])", name: "scheduled_lessons_attendance_status"
    t.check_constraint "ends_at > starts_at", name: "scheduled_lesson_time_order"
    t.check_constraint "teacher_attendance_status::text = ANY (ARRAY['not_checked_in'::character varying::text, 'on_time'::character varying::text, 'late'::character varying::text, 'absent'::character varying::text, 'administrator_override'::character varying::text])", name: "scheduled_lessons_teacher_attendance_status"
  end

  create_table "staff_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "display_name"
    t.integer "lock_version", default: 0, null: false
    t.string "phone_number", null: false
    t.string "public_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.string "whatsapp_number", null: false
    t.index ["created_by_id"], name: "index_staff_profiles_on_created_by_id"
    t.index ["public_id"], name: "index_staff_profiles_on_public_id", unique: true
    t.index ["updated_by_id"], name: "index_staff_profiles_on_updated_by_id"
    t.index ["user_id"], name: "index_staff_profiles_on_user_id", unique: true
  end

  create_table "student_assessment_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "student_assessment_id", null: false
    t.index ["actor_id"], name: "index_student_assessment_events_on_actor_id"
    t.index ["student_assessment_id", "created_at"], name: "idx_student_assessment_events_history"
    t.index ["student_assessment_id"], name: "index_student_assessment_events_on_student_assessment_id"
  end

  create_table "student_assessments", force: :cascade do |t|
    t.datetime "archived_at"
    t.date "assessment_date", null: false
    t.bigint "assessment_template_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "enrollment_id", null: false
    t.string "letter_grade"
    t.integer "lock_version", default: 0, null: false
    t.text "notes"
    t.decimal "overall_score", precision: 7, scale: 2
    t.string "public_id", null: false
    t.datetime "published_at"
    t.datetime "reviewed_at"
    t.bigint "reviewer_id"
    t.bigint "scheduled_lesson_id"
    t.string "status", default: "draft", null: false
    t.bigint "student_profile_id", null: false
    t.datetime "submitted_at"
    t.bigint "teacher_profile_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["assessment_template_id"], name: "index_student_assessments_on_assessment_template_id"
    t.index ["created_by_id"], name: "index_student_assessments_on_created_by_id"
    t.index ["enrollment_id", "assessment_template_id", "assessment_date"], name: "idx_assessments_enrollment_template_date"
    t.index ["enrollment_id"], name: "index_student_assessments_on_enrollment_id"
    t.index ["public_id"], name: "index_student_assessments_on_public_id", unique: true
    t.index ["reviewer_id"], name: "index_student_assessments_on_reviewer_id"
    t.index ["scheduled_lesson_id"], name: "index_student_assessments_on_scheduled_lesson_id"
    t.index ["student_profile_id", "assessment_date"], name: "idx_on_student_profile_id_assessment_date_45182c2b2a"
    t.index ["student_profile_id"], name: "index_student_assessments_on_student_profile_id"
    t.index ["teacher_profile_id", "status", "assessment_date"], name: "idx_assessments_teacher_status_date"
    t.index ["teacher_profile_id"], name: "index_student_assessments_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_student_assessments_on_updated_by_id"
    t.check_constraint "overall_score IS NULL OR overall_score >= 0::numeric AND overall_score <= 100::numeric", name: "assessment_score_range"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'submitted'::character varying::text, 'reviewed'::character varying::text, 'published'::character varying::text, 'archived'::character varying::text])", name: "student_assessment_status"
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
    t.string "account_delivery_method", default: "whatsapp", null: false
    t.bigint "assigned_teacher_profile_id"
    t.string "billing_currency", default: "EGP", null: false
    t.string "city"
    t.string "country_of_residence"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "current_quran_level", default: "beginner", null: false
    t.date "date_of_birth"
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.string "display_name"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "gender", default: "unspecified", null: false
    t.string "guardian_email"
    t.string "guardian_name"
    t.string "guardian_phone"
    t.text "internal_notes"
    t.date "joined_on"
    t.text "learning_goals"
    t.text "learning_notes"
    t.string "learning_status", default: "prospective", null: false
    t.date "left_on"
    t.integer "lesson_duration_minutes"
    t.text "medical_notes"
    t.string "memorization_level", default: "none", null: false
    t.integer "memorized_juz_count"
    t.text "memorized_surahs"
    t.string "nationality"
    t.string "native_language"
    t.string "package_name"
    t.string "phone_number"
    t.string "preferred_contact_method", default: "email", null: false
    t.string "preferred_interface_locale", default: "en", null: false
    t.string "preferred_learning_language"
    t.string "profile_status", default: "draft", null: false
    t.string "public_id", null: false
    t.string "reading_level", default: "not_started", null: false
    t.text "safeguarding_notes"
    t.jsonb "schedule_slots", default: [], null: false
    t.time "schedule_time"
    t.string "schedule_weekday"
    t.string "session_type", default: "individual", null: false
    t.integer "sessions_per_month"
    t.bigint "sibling_student_profile_id"
    t.text "special_learning_needs"
    t.string "student_type", default: "adult", null: false
    t.string "tajweed_level", default: "none", null: false
    t.datetime "trial_lesson_at"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.decimal "wallet_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "weekly_lesson_count"
    t.decimal "weekly_price", precision: 12, scale: 2, default: "0.0", null: false
    t.string "whatsapp_number"
    t.index ["assigned_teacher_profile_id"], name: "index_student_profiles_on_assigned_teacher_profile_id"
    t.index ["created_by_id"], name: "index_student_profiles_on_created_by_id"
    t.index ["date_of_birth"], name: "index_student_profiles_on_date_of_birth"
    t.index ["joined_on"], name: "index_student_profiles_on_joined_on"
    t.index ["learning_status"], name: "index_student_profiles_on_learning_status"
    t.index ["preferred_learning_language"], name: "index_student_profiles_on_preferred_learning_language"
    t.index ["profile_status"], name: "index_student_profiles_on_profile_status"
    t.index ["public_id"], name: "index_student_profiles_on_public_id", unique: true
    t.index ["sibling_student_profile_id"], name: "index_student_profiles_on_sibling_student_profile_id"
    t.index ["student_type"], name: "index_student_profiles_on_student_type"
    t.index ["updated_by_id"], name: "index_student_profiles_on_updated_by_id"
    t.index ["user_id"], name: "index_student_profiles_on_user_id", unique: true
    t.check_constraint "discount_percentage >= 0::numeric AND discount_percentage <= 100::numeric", name: "student_profiles_discount_range"
    t.check_constraint "left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on", name: "student_profiles_date_order"
    t.check_constraint "memorized_juz_count IS NULL OR memorized_juz_count >= 0 AND memorized_juz_count <= 30", name: "student_profiles_juz_range"
    t.check_constraint "wallet_balance >= 0::numeric", name: "student_profiles_wallet_nonnegative"
    t.check_constraint "weekly_price >= 0::numeric", name: "student_profiles_weekly_price_nonnegative"
  end

  create_table "student_progresses", force: :cascade do |t|
    t.decimal "average_score", precision: 7, scale: 2
    t.decimal "completion_percentage", precision: 7, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "current_ayah"
    t.integer "current_page"
    t.string "current_surah"
    t.decimal "highest_score", precision: 7, scale: 2
    t.boolean "ijazah_ready", default: false, null: false
    t.date "last_evaluation_date"
    t.bigint "latest_assessment_id"
    t.integer "lock_version", default: 0, null: false
    t.decimal "lowest_score", precision: 7, scale: 2
    t.decimal "memorization_progress", precision: 7, scale: 2, default: "0.0", null: false
    t.decimal "revision_progress", precision: 7, scale: 2, default: "0.0", null: false
    t.bigint "strongest_category_id"
    t.bigint "student_profile_id", null: false
    t.string "trend", default: "stable", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "weakest_category_id"
    t.index ["latest_assessment_id"], name: "index_student_progresses_on_latest_assessment_id"
    t.index ["strongest_category_id"], name: "index_student_progresses_on_strongest_category_id"
    t.index ["student_profile_id"], name: "index_student_progresses_on_student_profile_id", unique: true
    t.index ["trend", "average_score"], name: "index_student_progresses_on_trend_and_average_score"
    t.index ["updated_by_id"], name: "index_student_progresses_on_updated_by_id"
    t.index ["weakest_category_id"], name: "index_student_progresses_on_weakest_category_id"
    t.check_constraint "current_ayah IS NULL OR current_ayah >= 1", name: "progress_ayah_positive"
    t.check_constraint "current_page IS NULL OR current_page >= 1 AND current_page <= 604", name: "progress_page_range"
    t.check_constraint "memorization_progress >= 0::numeric AND memorization_progress <= 100::numeric AND revision_progress >= 0::numeric AND revision_progress <= 100::numeric AND completion_percentage >= 0::numeric AND completion_percentage <= 100::numeric", name: "progress_percentage_ranges"
    t.check_constraint "trend::text = ANY (ARRAY['improving'::character varying::text, 'stable'::character varying::text, 'needs_attention'::character varying::text])", name: "student_progress_trend"
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

  create_table "teacher_payroll_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.jsonb "after_data", default: {}, null: false
    t.jsonb "before_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "teacher_payroll_id", null: false
    t.index ["actor_id"], name: "index_teacher_payroll_events_on_actor_id"
    t.index ["teacher_payroll_id", "created_at"], name: "idx_payroll_events_history"
    t.index ["teacher_payroll_id"], name: "index_teacher_payroll_events_on_teacher_payroll_id"
  end

  create_table "teacher_payroll_items", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes", null: false
    t.decimal "rate", precision: 12, scale: 2, null: false
    t.bigint "scheduled_lesson_id", null: false
    t.bigint "teacher_payroll_id", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_lesson_id"], name: "index_teacher_payroll_items_on_scheduled_lesson_id"
    t.index ["teacher_payroll_id", "scheduled_lesson_id"], name: "idx_payroll_lesson", unique: true
    t.index ["teacher_payroll_id"], name: "index_teacher_payroll_items_on_teacher_payroll_id"
    t.check_constraint "duration_minutes >= 0 AND rate >= 0::numeric AND amount >= 0::numeric", name: "payroll_items_nonnegative"
  end

  create_table "teacher_payrolls", force: :cascade do |t|
    t.text "adjustment_reason"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.decimal "base_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bonus_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "calculation_strategy", null: false
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "currency", null: false
    t.decimal "deduction_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "lock_version", default: 0, null: false
    t.decimal "manual_adjustment_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "net_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "paid_at"
    t.bigint "paid_by_id"
    t.date "period_ends_on", null: false
    t.date "period_starts_on", null: false
    t.datetime "prepared_at"
    t.bigint "prepared_by_id"
    t.string "public_id", null: false
    t.decimal "rate", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "draft", null: false
    t.bigint "teacher_profile_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id", null: false
    t.index ["approved_by_id"], name: "index_teacher_payrolls_on_approved_by_id"
    t.index ["cancelled_by_id"], name: "index_teacher_payrolls_on_cancelled_by_id"
    t.index ["created_by_id"], name: "index_teacher_payrolls_on_created_by_id"
    t.index ["paid_by_id"], name: "index_teacher_payrolls_on_paid_by_id"
    t.index ["prepared_by_id"], name: "index_teacher_payrolls_on_prepared_by_id"
    t.index ["public_id"], name: "index_teacher_payrolls_on_public_id", unique: true
    t.index ["status", "period_starts_on", "period_ends_on"], name: "idx_payroll_status_period"
    t.index ["teacher_profile_id", "period_starts_on", "period_ends_on"], name: "idx_payroll_teacher_period", unique: true
    t.index ["teacher_profile_id"], name: "index_teacher_payrolls_on_teacher_profile_id"
    t.index ["updated_by_id"], name: "index_teacher_payrolls_on_updated_by_id"
    t.check_constraint "base_amount >= 0::numeric AND bonus_amount >= 0::numeric AND deduction_amount >= 0::numeric AND rate >= 0::numeric", name: "payroll_nonnegative_amounts"
    t.check_constraint "period_ends_on >= period_starts_on", name: "payroll_period_order"
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
    t.string "message_language", default: "ar", null: false
    t.boolean "mid_period_previous_dues", default: false, null: false
    t.decimal "monthly_salary", precision: 12, scale: 2, default: "0.0", null: false
    t.string "nationality"
    t.string "notification_method", default: "whatsapp", null: false
    t.boolean "on_leave", default: false, null: false
    t.string "online_meeting_url"
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
    t.string "work_days", default: [], null: false, array: true
    t.time "work_end_time"
    t.time "work_start_time"
    t.integer "workload_percentage", default: 0, null: false
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
    t.check_constraint "monthly_salary >= 0::numeric", name: "teacher_profiles_monthly_salary_nonnegative"
    t.check_constraint "quran_teaching_experience_years >= 0", name: "teacher_profiles_quran_experience_nonnegative"
    t.check_constraint "workload_percentage >= 0 AND workload_percentage <= 100", name: "teacher_profiles_workload_range"
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
    t.string "account_delivery_method", default: "email", null: false
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
  add_foreign_key "account_invitation_events", "account_invitations", on_delete: :restrict
  add_foreign_key "account_invitation_events", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "account_invitations", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "account_invitations", "users", on_delete: :restrict
  add_foreign_key "assessment_categories", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "assessment_categories", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "assessment_rubric_items", "assessment_categories", on_delete: :restrict
  add_foreign_key "assessment_rubric_items", "assessment_templates", on_delete: :restrict
  add_foreign_key "assessment_scores", "assessment_rubric_items", on_delete: :restrict
  add_foreign_key "assessment_scores", "student_assessments", on_delete: :restrict
  add_foreign_key "assessment_templates", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "assessment_templates", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "certificate_events", "certificates", on_delete: :restrict
  add_foreign_key "certificate_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "certificates", "enrollments", on_delete: :restrict
  add_foreign_key "certificates", "exam_sessions", on_delete: :restrict
  add_foreign_key "certificates", "student_profiles", on_delete: :restrict
  add_foreign_key "certificates", "users", column: "issuer_id", on_delete: :restrict
  add_foreign_key "communication_log_events", "communication_logs", on_delete: :restrict
  add_foreign_key "communication_log_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "communication_logs", "guardians", on_delete: :restrict
  add_foreign_key "communication_logs", "lesson_reports", on_delete: :restrict
  add_foreign_key "communication_logs", "lesson_student_reports", on_delete: :restrict
  add_foreign_key "communication_logs", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "communication_logs", "student_profiles", on_delete: :restrict
  add_foreign_key "communication_logs", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "communication_logs", "users", column: "confirmed_by_id", on_delete: :nullify
  add_foreign_key "communication_logs", "users", column: "recipient_user_id", on_delete: :nullify
  add_foreign_key "course_offering_events", "course_offerings", on_delete: :restrict
  add_foreign_key "course_offering_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "course_offerings", "programs", on_delete: :restrict
  add_foreign_key "course_offerings", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "course_offerings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "enrollment_events", "enrollments", on_delete: :restrict
  add_foreign_key "enrollment_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "enrollment_lesson_generation_issues", "enrollment_lesson_schedule_slots", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedule_events", "enrollment_lesson_schedules", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedule_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedule_slots", "enrollment_lesson_schedules", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedules", "enrollments", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedules", "teacher_profiles", on_delete: :restrict
  add_foreign_key "enrollment_lesson_schedules", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "enrollment_lesson_schedules", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "course_offerings", on_delete: :restrict
  add_foreign_key "enrollments", "student_profiles", on_delete: :restrict
  add_foreign_key "enrollments", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "ended_by_id", on_delete: :nullify
  add_foreign_key "enrollments", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "exam_session_events", "exam_sessions", on_delete: :restrict
  add_foreign_key "exam_session_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "exam_sessions", "course_offerings", on_delete: :restrict
  add_foreign_key "exam_sessions", "programs", on_delete: :restrict
  add_foreign_key "exam_sessions", "teacher_profiles", on_delete: :restrict
  add_foreign_key "exam_sessions", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "exam_sessions", "users", column: "updated_by_id", on_delete: :restrict
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
  add_foreign_key "lesson_report_events", "lesson_reports", on_delete: :restrict
  add_foreign_key "lesson_report_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "lesson_reports", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "lesson_reports", "teacher_profiles", on_delete: :restrict
  add_foreign_key "lesson_reports", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "lesson_reports", "users", column: "locked_by_id", on_delete: :nullify
  add_foreign_key "lesson_reports", "users", column: "reopened_by_id", on_delete: :nullify
  add_foreign_key "lesson_reports", "users", column: "reviewed_by_id", on_delete: :nullify
  add_foreign_key "lesson_reports", "users", column: "submitted_by_id", on_delete: :nullify
  add_foreign_key "lesson_reports", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "lesson_student_report_events", "lesson_student_reports", on_delete: :restrict
  add_foreign_key "lesson_student_report_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "lesson_student_reports", "lesson_reports", on_delete: :restrict
  add_foreign_key "lesson_student_reports", "scheduled_lesson_enrollments", on_delete: :restrict
  add_foreign_key "lesson_student_reports", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "lesson_student_reports", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "notification_attempts", "notifications", on_delete: :restrict
  add_foreign_key "notification_attempts", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "notification_events", "notifications", on_delete: :restrict
  add_foreign_key "notification_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "notifications", "guardians", column: "recipient_guardian_id", on_delete: :restrict
  add_foreign_key "notifications", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "notifications", "users", column: "recipient_user_id", on_delete: :restrict
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
  add_foreign_key "scheduled_lessons", "enrollment_lesson_schedule_slots", on_delete: :restrict
  add_foreign_key "scheduled_lessons", "teacher_profiles", on_delete: :restrict
  add_foreign_key "scheduled_lessons", "users", column: "attendance_locked_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "attendance_reopened_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "cancelled_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "scheduled_lessons", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "staff_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "staff_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "staff_profiles", "users", on_delete: :restrict
  add_foreign_key "student_assessment_events", "student_assessments", on_delete: :restrict
  add_foreign_key "student_assessment_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "student_assessments", "assessment_templates", on_delete: :restrict
  add_foreign_key "student_assessments", "enrollments", on_delete: :restrict
  add_foreign_key "student_assessments", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "student_assessments", "student_profiles", on_delete: :restrict
  add_foreign_key "student_assessments", "teacher_profiles", on_delete: :restrict
  add_foreign_key "student_assessments", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "student_assessments", "users", column: "reviewer_id", on_delete: :nullify
  add_foreign_key "student_assessments", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "student_guardianship_events", "student_guardianships", on_delete: :restrict
  add_foreign_key "student_guardianship_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "student_guardianships", "guardians", on_delete: :restrict
  add_foreign_key "student_guardianships", "student_profiles", on_delete: :restrict
  add_foreign_key "student_guardianships", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "student_guardianships", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "student_profile_events", "student_profiles", on_delete: :restrict
  add_foreign_key "student_profile_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "student_profiles", "student_profiles", column: "sibling_student_profile_id"
  add_foreign_key "student_profiles", "teacher_profiles", column: "assigned_teacher_profile_id"
  add_foreign_key "student_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "student_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "student_profiles", "users", on_delete: :restrict
  add_foreign_key "student_progresses", "assessment_categories", column: "strongest_category_id", on_delete: :nullify
  add_foreign_key "student_progresses", "assessment_categories", column: "weakest_category_id", on_delete: :nullify
  add_foreign_key "student_progresses", "student_assessments", column: "latest_assessment_id", on_delete: :nullify
  add_foreign_key "student_progresses", "student_profiles", on_delete: :restrict
  add_foreign_key "student_progresses", "users", column: "updated_by_id", on_delete: :nullify
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
  add_foreign_key "teacher_payroll_events", "teacher_payrolls", on_delete: :restrict
  add_foreign_key "teacher_payroll_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_payroll_items", "scheduled_lessons", on_delete: :restrict
  add_foreign_key "teacher_payroll_items", "teacher_payrolls", on_delete: :restrict
  add_foreign_key "teacher_payrolls", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_payrolls", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "teacher_payrolls", "users", column: "cancelled_by_id", on_delete: :nullify
  add_foreign_key "teacher_payrolls", "users", column: "created_by_id", on_delete: :restrict
  add_foreign_key "teacher_payrolls", "users", column: "paid_by_id", on_delete: :nullify
  add_foreign_key "teacher_payrolls", "users", column: "prepared_by_id", on_delete: :nullify
  add_foreign_key "teacher_payrolls", "users", column: "updated_by_id", on_delete: :restrict
  add_foreign_key "teacher_profile_events", "teacher_profiles", on_delete: :restrict
  add_foreign_key "teacher_profile_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "teacher_profiles", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "teacher_profiles", "users", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "actor_id", on_delete: :restrict
  add_foreign_key "user_account_events", "users", column: "target_user_id", on_delete: :restrict
  add_foreign_key "users", "users", column: "approved_by_id", on_delete: :nullify
end
