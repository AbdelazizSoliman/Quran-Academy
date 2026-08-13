class CourseOfferingTeacher < ApplicationRecord
  belongs_to :course_offering, inverse_of: :course_offering_teachers
  belongs_to :teacher_profile, inverse_of: :course_offering_teachers
  belongs_to :created_by, class_name: "User", optional: true

  validates :teacher_profile_id, uniqueness: { scope: :course_offering_id }
end
