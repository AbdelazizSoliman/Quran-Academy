class CreateCourseOfferingTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :course_offering_teachers do |t|
      t.references :course_offering, null: false, foreign_key: true
      t.references :teacher_profile, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :course_offering_teachers, %i[course_offering_id teacher_profile_id],
              unique: true, name: "idx_course_offering_teachers_unique"
  end
end
