class CreateTeacherScheduling < ActiveRecord::Migration[8.1]
  def change
    create_table :teacher_availabilities do |t|
      t.string :public_id, null: false
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.string :weekday, null: false
      t.time :starts_at_local, null: false
      t.time :ends_at_local, null: false
      t.string :time_zone, null: false, default: "Cairo"
      t.date :effective_from, null: false
      t.date :effective_until
      t.string :availability_type, null: false, default: "teaching"
      t.string :status, null: false, default: "active"
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :teacher_availabilities, :public_id, unique: true
    add_index :teacher_availabilities, %i[teacher_profile_id weekday status]
    add_check_constraint :teacher_availabilities, "ends_at_local > starts_at_local",
                         name: "teacher_availability_time_order"
    add_check_constraint :teacher_availabilities, "effective_until IS NULL OR effective_until >= effective_from",
                         name: "teacher_availability_date_order"

    create_table :teacher_availability_exceptions do |t|
      t.string :public_id, null: false
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.date :exception_date, null: false
      t.time :starts_at_local
      t.time :ends_at_local
      t.string :time_zone, null: false, default: "Cairo"
      t.string :exception_type, null: false
      t.string :status, null: false, default: "active"
      t.string :reason
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :teacher_availability_exceptions, :public_id, unique: true
    add_index :teacher_availability_exceptions, %i[teacher_profile_id exception_date status]
    add_check_constraint :teacher_availability_exceptions,
                         "(starts_at_local IS NULL AND ends_at_local IS NULL) OR " \
                         "(starts_at_local IS NOT NULL AND ends_at_local IS NOT NULL AND " \
                         "ends_at_local > starts_at_local)",
                         name: "teacher_exception_time_order"

    create_table :scheduled_lessons do |t|
      t.string :public_id, null: false
      t.references :course_offering, null: false, foreign_key: { on_delete: :restrict }
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.string :title_ar, null: false
      t.string :title_en, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :academy_time_zone, null: false, default: "Cairo"
      t.string :delivery_mode, null: false, default: "online"
      t.string :location_name
      t.string :online_meeting_url
      t.string :status, null: false, default: "draft"
      t.string :scheduling_source, null: false, default: "manual"
      t.text :cancellation_reason
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :completed_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :scheduled_lessons, :public_id, unique: true
    add_index :scheduled_lessons, %i[teacher_profile_id starts_at ends_at]
    add_index :scheduled_lessons, %i[course_offering_id starts_at]
    add_index :scheduled_lessons, %i[status starts_at]
    add_check_constraint :scheduled_lessons, "ends_at > starts_at", name: "scheduled_lesson_time_order"

    create_table :scheduled_lesson_enrollments do |t|
      t.references :scheduled_lesson, null: false, foreign_key: { on_delete: :restrict }
      t.references :enrollment, null: false, foreign_key: { on_delete: :restrict }
      t.string :participation_status, null: false, default: "expected"
      t.references :added_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :scheduled_lesson_enrollments, %i[scheduled_lesson_id enrollment_id],
              unique: true, name: "index_scheduled_lesson_enrollments_unique"
    add_index :scheduled_lesson_enrollments, :participation_status

    create_event_table :teacher_availability_events, :teacher_availability
    create_event_table :teacher_availability_exception_events, :teacher_availability_exception
    create_event_table :scheduled_lesson_events, :scheduled_lesson
  end

  private

  def create_event_table(name, target)
    create_table name do |t|
      t.references target, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index name, [:"#{target}_id", :created_at]
    add_index name, :event_type
  end
end
