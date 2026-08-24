class AllowDirectStudentAssessments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :student_assessments, :enrollment_id, true
  end
end
