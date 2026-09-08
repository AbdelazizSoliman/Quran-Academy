class PreventDuplicateLessonAssessments < ActiveRecord::Migration[8.1]
  def change
    add_index :student_assessments,
              %i[scheduled_lesson_id student_profile_id assessment_template_id],
              unique: true, where: "scheduled_lesson_id IS NOT NULL",
              name: "idx_unique_lesson_student_assessment"
  end
end
