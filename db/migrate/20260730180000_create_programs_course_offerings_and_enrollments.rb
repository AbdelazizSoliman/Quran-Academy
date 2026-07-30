# This migration is intentionally grouped so the catalog tables are introduced atomically.
# rubocop:disable Metrics/ClassLength
class CreateProgramsCourseOfferingsAndEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_programs
    create_course_offerings
    create_enrollments
    create_event_table(:program_events, :program)
    create_event_table(:course_offering_events, :course_offering)
    create_event_table(:enrollment_events, :enrollment)
  end

  private

  def create_programs
    create_table :programs do |t|
      t.string :public_id, null: false
      t.string :code, null: false
      t.string :name_ar, null: false
      t.string :name_en, null: false
      t.text :short_description_ar
      t.text :short_description_en
      t.text :description_ar
      t.text :description_en
      t.string :category, null: false
      t.string :status, null: false, default: "draft"
      t.string :default_learning_language, null: false
      t.string :supported_learning_languages, array: true, null: false, default: []
      t.string :target_age_groups, array: true, null: false, default: []
      t.string :entry_level, null: false, default: "not_started"
      t.string :completion_level, null: false, default: "intermediate"
      t.integer :default_lesson_duration_minutes, null: false, default: 30
      t.integer :recommended_lessons_per_week, null: false, default: 2
      t.integer :estimated_duration_weeks
      t.boolean :requires_placement, null: false, default: false
      t.boolean :allows_minor_students, null: false, default: true
      t.boolean :allows_adult_students, null: false, default: true
      t.integer :display_order, null: false, default: 0
      t.text :internal_notes
      actor_references(t)
      t.timestamps
    end
    add_index :programs, :public_id, unique: true
    add_index :programs, "lower(code)", unique: true, name: "index_programs_on_lower_code"
    add_index :programs, :status
    add_index :programs, :category
    add_index :programs, :display_order
    add_index :programs, :supported_learning_languages, using: :gin
    add_index :programs, :target_age_groups, using: :gin
    add_check_constraint :programs, "default_lesson_duration_minutes > 0", name: "programs_duration_positive"
    add_check_constraint :programs, "recommended_lessons_per_week > 0", name: "programs_frequency_positive"
    add_check_constraint :programs, "estimated_duration_weeks IS NULL OR estimated_duration_weeks >= 0",
                         name: "programs_duration_weeks_nonnegative"
  end

  def create_course_offerings
    create_table :course_offerings do |t|
      t.references :program, null: false, foreign_key: { on_delete: :restrict }
      t.string :public_id, null: false
      t.string :code, null: false
      t.string :title_ar, null: false
      t.string :title_en, null: false
      t.text :description_ar
      t.text :description_en
      t.string :status, null: false, default: "draft"
      t.string :learning_language, null: false
      t.string :delivery_mode, null: false, default: "online"
      t.string :target_age_groups, array: true, null: false, default: []
      t.date :enrollment_opens_on
      t.date :enrollment_closes_on
      t.date :planned_start_on
      t.date :planned_end_on
      t.integer :capacity
      t.integer :default_lesson_duration_minutes, null: false
      t.integer :intended_lessons_per_week, null: false
      t.boolean :placement_required, null: false, default: false
      t.boolean :accepts_new_enrollments, null: false, default: false
      t.text :internal_notes
      actor_references(t)
      t.timestamps
    end
    add_index :course_offerings, :public_id, unique: true
    add_index :course_offerings, "lower(code)", unique: true, name: "index_course_offerings_on_lower_code"
    add_index :course_offerings, :status
    add_index :course_offerings, :learning_language
    add_index :course_offerings, :delivery_mode
    add_index :course_offerings, :planned_start_on
    add_index :course_offerings, :enrollment_closes_on
    add_index :course_offerings, :accepts_new_enrollments
    add_index :course_offerings, :target_age_groups, using: :gin
    add_check_constraint :course_offerings, "capacity IS NULL OR capacity > 0", name: "offerings_capacity_positive"
    add_check_constraint :course_offerings, "default_lesson_duration_minutes > 0",
                         name: "offerings_duration_positive"
    add_check_constraint :course_offerings, "intended_lessons_per_week > 0",
                         name: "offerings_frequency_positive"
    add_check_constraint :course_offerings,
                         "enrollment_closes_on IS NULL OR enrollment_opens_on IS NULL OR " \
                         "enrollment_closes_on >= enrollment_opens_on",
                         name: "offerings_enrollment_date_order"
    add_check_constraint :course_offerings,
                         "planned_end_on IS NULL OR planned_start_on IS NULL OR planned_end_on >= planned_start_on",
                         name: "offerings_planned_date_order"
  end

  def create_enrollments
    create_table :enrollments do |t|
      t.string :public_id, null: false
      t.references :student_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :course_offering, null: false, foreign_key: { on_delete: :restrict }
      t.string :status, null: false, default: "pending"
      t.string :application_source, null: false, default: "administrator"
      t.date :applied_on, null: false
      t.date :approved_on
      t.date :started_on
      t.date :paused_on
      t.date :resumed_on
      t.date :completed_on
      t.date :withdrawn_on
      t.date :cancelled_on
      t.date :rejected_on
      t.date :ended_on
      t.string :exit_reason
      t.text :exit_notes
      t.string :placement_status, null: false, default: "not_required"
      t.string :placement_method
      t.date :placement_completed_on
      t.string :starting_quran_level
      t.string :starting_reading_level
      t.string :starting_tajweed_level
      t.string :starting_memorization_level
      t.integer :starting_memorized_juz_count
      t.text :placement_notes
      t.text :student_goals_snapshot
      t.text :preferred_schedule_notes
      t.text :administrator_notes
      actor_references(t)
      t.references :approved_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :ended_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :enrollments, :public_id, unique: true
    add_index :enrollments, %i[student_profile_id course_offering_id], unique: true,
                                                                       name: "index_enrollments_unique_membership"
    add_index :enrollments, :status
    add_index :enrollments, :placement_status
    add_index :enrollments, :application_source
    add_index :enrollments, :applied_on
    add_index :enrollments, :started_on
    add_index :enrollments, %i[course_offering_id status]
    add_index :enrollments, %i[student_profile_id created_at]
    add_check_constraint :enrollments,
                         "starting_memorized_juz_count IS NULL OR starting_memorized_juz_count BETWEEN 0 AND 30",
                         name: "enrollments_starting_juz_range"
  end

  def actor_references(table)
    table.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
    table.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
  end

  def create_event_table(table_name, target)
    create_table table_name do |t|
      t.references target, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index table_name, [:"#{target}_id", :created_at]
    add_index table_name, :event_type
  end
end
# rubocop:enable Metrics/ClassLength
