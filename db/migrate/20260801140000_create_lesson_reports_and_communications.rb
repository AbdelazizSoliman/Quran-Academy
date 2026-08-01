# This migration is intentionally declarative so clean schema loads preserve all
# reporting, communication, audit, index, and constraint definitions together.
# rubocop:disable Metrics/ClassLength
class CreateLessonReportsAndCommunications < ActiveRecord::Migration[8.1]
  REPORT_STATUSES = %w[draft submitted reviewed locked reopened archived].freeze
  ENTRY_STATUSES = %w[pending completed not_applicable withheld].freeze
  COMMUNICATION_STATUSES = %w[prepared opened confirmed_sent cancelled failed].freeze

  def change
    create_lesson_reports
    create_lesson_student_reports
    create_communication_logs
    create_audit_tables
  end

  private

  def create_lesson_reports
    create_table :lesson_reports do |t|
      t.string :public_id, null: false
      t.references :scheduled_lesson, null: false, index: { unique: true }, foreign_key: { on_delete: :restrict }
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.string :status, null: false, default: "draft"
      t.text :lesson_summary
      t.text :topics_covered
      t.text :general_teacher_notes
      t.text :general_homework
      t.text :next_lesson_plan
      t.string :overall_engagement, null: false, default: "not_assessed"
      t.string :overall_progress, null: false, default: "not_assessed"
      t.string :report_language, null: false, default: "ar"
      t.datetime :submitted_at
      t.references :submitted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :reopened_at
      t.references :reopened_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :reopening_reason
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lesson_reports, :public_id, unique: true
    add_index :lesson_reports, %i[status created_at]
    add_index :lesson_reports, :submitted_at
    add_index :lesson_reports, :reviewed_at
    add_index :lesson_reports, :locked_at
    add_check_constraint :lesson_reports, "status IN (#{quoted(REPORT_STATUSES)})",
                         name: "lesson_reports_status"
  end

  def create_lesson_student_reports
    create_table :lesson_student_reports do |t|
      t.string :public_id, null: false
      t.references :lesson_report, null: false, foreign_key: { on_delete: :restrict }
      t.references :scheduled_lesson_enrollment, null: false, foreign_key: { on_delete: :restrict }
      t.string :status, null: false, default: "pending"
      t.string :reading_material
      t.string :reading_from
      t.string :reading_to
      t.string :reading_quality, null: false, default: "not_assessed"
      t.text :reading_notes
      t.string :memorization_material
      t.string :memorization_from
      t.string :memorization_to
      t.string :memorization_result, null: false, default: "not_assessed"
      t.text :memorization_notes
      t.string :revision_material
      t.string :revision_result, null: false, default: "not_assessed"
      t.text :revision_notes
      t.string :tajweed_topics, array: true, null: false, default: []
      t.text :tajweed_observations
      t.text :mistakes_summary
      t.text :strengths
      t.text :areas_for_improvement
      t.string :engagement_level, null: false, default: "not_assessed"
      t.string :performance_level, null: false, default: "not_assessed"
      t.text :homework
      t.text :next_lesson_target
      t.text :private_teacher_notes
      t.text :student_visible_notes
      t.text :guardian_visible_notes
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lesson_student_reports, :public_id, unique: true
    add_index :lesson_student_reports, %i[lesson_report_id scheduled_lesson_enrollment_id],
              unique: true, name: "idx_student_report_entry"
    add_index :lesson_student_reports, %i[status engagement_level performance_level],
              name: "idx_student_report_outcomes"
    add_check_constraint :lesson_student_reports, "status IN (#{quoted(ENTRY_STATUSES)})",
                         name: "lesson_student_reports_status"
  end

  def create_communication_logs
    create_table :communication_logs do |t|
      t.string :public_id, null: false
      t.references :scheduled_lesson, foreign_key: { on_delete: :restrict }
      t.references :lesson_report, foreign_key: { on_delete: :restrict }
      t.references :lesson_student_report, foreign_key: { on_delete: :restrict }
      t.references :student_profile, foreign_key: { on_delete: :restrict }
      t.references :guardian, foreign_key: { on_delete: :restrict }
      t.references :recipient_user, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :channel, null: false
      t.string :template_type, null: false
      t.string :recipient_address_masked, null: false
      t.string :recipient_locale, null: false
      t.text :message_snapshot, null: false
      t.string :subject_snapshot
      t.string :external_url
      t.string :status, null: false, default: "prepared"
      t.datetime :prepared_at, null: false
      t.datetime :opened_at
      t.datetime :confirmed_sent_at
      t.references :confirmed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :failure_reason
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :communication_logs, :public_id, unique: true
    add_index :communication_logs, %i[channel template_type status]
    add_index :communication_logs, :prepared_at
    add_index :communication_logs, :confirmed_sent_at
    add_check_constraint :communication_logs, "status IN (#{quoted(COMMUNICATION_STATUSES)})",
                         name: "communication_logs_status"
    add_check_constraint :communication_logs, "channel IN ('whatsapp', 'email')",
                         name: "communication_logs_channel"
  end

  def create_audit_tables
    create_event_table :lesson_report_events, :lesson_report
    create_event_table :lesson_student_report_events, :lesson_student_report
    create_event_table :communication_log_events, :communication_log
  end

  def create_event_table(table, target)
    create_table table do |t|
      t.references target, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index table, [:"#{target}_id", :created_at]
    add_index table, :event_type
  end

  def quoted(values)
    values.map { |value| connection.quote(value) }.join(", ")
  end
end
# rubocop:enable Metrics/ClassLength
