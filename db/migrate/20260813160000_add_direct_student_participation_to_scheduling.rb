class AddDirectStudentParticipationToScheduling < ActiveRecord::Migration[8.1]
  def change
    change_column_null :enrollment_lesson_schedules, :enrollment_id, true
    add_reference :enrollment_lesson_schedules, :student_profile, null: true, index: true,
                                                                  foreign_key: { on_delete: :restrict }
    add_check_constraint :enrollment_lesson_schedules,
                         "enrollment_id IS NOT NULL OR student_profile_id IS NOT NULL",
                         name: "enrollment_lesson_schedules_participant_required"

    change_column_null :scheduled_lesson_enrollments, :enrollment_id, true
    add_reference :scheduled_lesson_enrollments, :student_profile, null: true, index: true,
                                                                   foreign_key: { on_delete: :restrict }
    add_index :scheduled_lesson_enrollments, %i[scheduled_lesson_id student_profile_id],
              unique: true, name: "index_scheduled_lesson_enrollments_direct_unique"
    add_check_constraint :scheduled_lesson_enrollments,
                         "enrollment_id IS NOT NULL OR student_profile_id IS NOT NULL",
                         name: "scheduled_lesson_enrollments_participant_required"

    change_column_null :scheduled_lessons, :course_offering_id, true
  end
end
