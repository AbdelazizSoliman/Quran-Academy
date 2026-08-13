class AddExistingStudentFieldsToStudentProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :student_profiles, :existing_student, :boolean, default: false, null: false
    add_column :student_profiles, :prior_sessions_taken, :integer
    add_column :student_profiles, :remaining_sessions_at_onboarding, :integer
  end
end
