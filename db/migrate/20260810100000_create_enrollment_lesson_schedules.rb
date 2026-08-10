class CreateEnrollmentLessonSchedules < ActiveRecord::Migration[8.1]
  def change
    create_schedules
    create_slots
    create_events
    create_generation_issues
    link_scheduled_lessons
  end

  private

  def create_schedules
    create_table :enrollment_lesson_schedules do |t|
      t.string :public_id, null: false
      t.references :enrollment, null: false, foreign_key: { on_delete: :restrict }
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.date :starts_on, null: false
      t.date :ends_on
      t.integer :lesson_duration_minutes, null: false
      t.string :time_zone, null: false
      t.string :status, null: false, default: "active"
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :enrollment_lesson_schedules, :public_id, unique: true
    add_index :enrollment_lesson_schedules, %i[enrollment_id status]
    add_check_constraint :enrollment_lesson_schedules,
                         "ends_on IS NULL OR ends_on >= starts_on", name: "enrollment_schedule_date_order"
    add_check_constraint :enrollment_lesson_schedules,
                         "lesson_duration_minutes > 0", name: "enrollment_schedule_duration_positive"
  end

  def create_slots
    create_table :enrollment_lesson_schedule_slots do |t|
      t.references :enrollment_lesson_schedule, null: false, foreign_key: { on_delete: :restrict },
                                                index: { name: "idx_schedule_slots_on_schedule" }
      t.string :weekday, null: false
      t.time :starts_at_local, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :enrollment_lesson_schedule_slots,
              %i[enrollment_lesson_schedule_id weekday starts_at_local], unique: true,
                                                                         name: "idx_schedule_slots_unique_weekday_time"
  end

  def create_events
    create_table :enrollment_lesson_schedule_events do |t|
      t.references :enrollment_lesson_schedule, null: false, foreign_key: { on_delete: :restrict },
                                                index: { name: "idx_schedule_events_on_schedule" }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :enrollment_lesson_schedule_events, %i[enrollment_lesson_schedule_id created_at],
              name: "idx_schedule_events_chronological"
  end

  def create_generation_issues
    create_table :enrollment_lesson_generation_issues do |t|
      t.references :enrollment_lesson_schedule_slot, null: false, foreign_key: { on_delete: :restrict },
                                                     index: { name: "idx_generation_issues_on_slot" }
      t.date :recurrence_date, null: false
      t.string :reason_code, null: false
      t.jsonb :details, null: false, default: {}
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :enrollment_lesson_generation_issues,
              %i[enrollment_lesson_schedule_slot_id recurrence_date], unique: true,
                                                                      name: "idx_generation_issues_unique_occurrence"
  end

  def link_scheduled_lessons
    add_reference :scheduled_lessons, :enrollment_lesson_schedule_slot,
                  foreign_key: { on_delete: :restrict }, index: { name: "idx_lessons_on_recurrence_slot" }
    add_column :scheduled_lessons, :recurrence_date, :date
    add_index :scheduled_lessons,
              %i[enrollment_lesson_schedule_slot_id recurrence_date],
              unique: true,
              name: "idx_scheduled_lessons_unique_recurrence"
  end
end
