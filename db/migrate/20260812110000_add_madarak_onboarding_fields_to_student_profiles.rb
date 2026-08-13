class AddMadarakOnboardingFieldsToStudentProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :student_profiles, :attendance_percentage, :decimal, precision: 5, scale: 2,
                                                                      default: 100.0, null: false
    add_column :student_profiles, :schedule_generation_weeks, :integer
  end
end
