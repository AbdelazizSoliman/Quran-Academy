class AddOneActiveEnrollmentScheduleIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :enrollment_lesson_schedules, :enrollment_id, unique: true, where: "status = 'active'",
                                                            name: "idx_enrollment_schedules_one_active"
  end
end
