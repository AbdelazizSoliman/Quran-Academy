class AddLessonOperationsAndAttendance < ActiveRecord::Migration[8.1]
  ATTENDANCE_STATUSES = %w[pending present late absent excused_absence left_early lesson_cancelled
                           not_applicable].freeze
  WORKFLOW_STATUSES = %w[not_opened open locked reopened].freeze
  TEACHER_STATUSES = %w[not_checked_in on_time late absent administrator_override].freeze

  def change
    add_lesson_operation_columns
    add_attendance_settings
    create_lesson_attendances
    create_lesson_attendance_events
  end

  private

  def add_lesson_operation_columns
    change_table :scheduled_lessons, bulk: true do |t|
      t.datetime :teacher_checked_in_at
      t.string :teacher_attendance_status, null: false, default: "not_checked_in"
      t.datetime :started_at
      t.datetime :ended_at
      t.string :attendance_status, null: false, default: "not_opened"
      t.datetime :attendance_opened_at
      t.datetime :attendance_locked_at
      t.references :attendance_locked_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :attendance_reopened_at
      t.references :attendance_reopened_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.text :completion_notes
      t.text :operation_notes
    end
    add_check_constraint :scheduled_lessons, "attendance_status IN (#{quoted(WORKFLOW_STATUSES)})",
                         name: "scheduled_lessons_attendance_status"
    add_check_constraint :scheduled_lessons, "teacher_attendance_status IN (#{quoted(TEACHER_STATUSES)})",
                         name: "scheduled_lessons_teacher_attendance_status"
    add_index :scheduled_lessons, %i[attendance_status starts_at]
  end

  def add_attendance_settings
    add_column :academy_settings, :teacher_check_in_opens_minutes_before, :integer, null: false, default: 15
    add_column :academy_settings, :teacher_check_in_closes_minutes_after, :integer, null: false, default: 30
    add_column :academy_settings, :left_early_threshold_minutes, :integer, null: false, default: 5
  end

  def create_lesson_attendances
    create_table :lesson_attendances do |t|
      t.string :public_id, null: false
      t.references :scheduled_lesson, null: false, foreign_key: { on_delete: :restrict }
      t.references :scheduled_lesson_enrollment, null: false, foreign_key: { on_delete: :restrict }
      t.string :status, null: false, default: "pending"
      t.datetime :arrival_at
      t.datetime :departure_at
      t.integer :minutes_late, null: false, default: 0
      t.string :excuse_reason
      t.text :notes
      t.datetime :recorded_at
      t.references :recorded_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :last_adjusted_at
      t.references :last_adjusted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :adjustment_reason
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lesson_attendances, :public_id, unique: true
    add_index :lesson_attendances, :scheduled_lesson_enrollment_id, unique: true,
                                                                    name: "idx_lesson_attendance_participant_unique"
    add_index :lesson_attendances, %i[status arrival_at]
    add_check_constraint :lesson_attendances, "status IN (#{quoted(ATTENDANCE_STATUSES)})",
                         name: "lesson_attendances_status"
    add_check_constraint :lesson_attendances, "minutes_late >= 0", name: "lesson_attendances_nonnegative_lateness"
    time_order = "departure_at IS NULL OR arrival_at IS NULL OR departure_at >= arrival_at"
    add_check_constraint :lesson_attendances, time_order,
                         name: "lesson_attendances_time_order"
  end

  def create_lesson_attendance_events
    create_table :lesson_attendance_events do |t|
      t.references :lesson_attendance, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :lesson_attendance_events, %i[lesson_attendance_id created_at],
              name: "idx_attendance_events_record_created"
    add_index :lesson_attendance_events, :event_type
  end

  def quoted(values)
    values.map { |value| connection.quote(value) }.join(", ")
  end
end
