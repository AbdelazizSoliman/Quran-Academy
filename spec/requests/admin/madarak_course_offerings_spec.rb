require "rails_helper"

RSpec.describe "Madarak-matching course offering workflow" do
  let(:admin) { create(:user, :admin) }

  before do
    AcademySetting.current.update!(teaching_languages: %w[ar en])
    sign_in admin
  end

  it "creates a course with teachers and initial student enrollments in one workflow" do
    program = create(:program, :active)
    teacher = create(:teacher_profile, :active, :verified, display_name: "Course Teacher")
    students = create_list(:student_profile, 2, :complete)

    expect do
      post admin_course_offerings_path, params: {
        course_offering: valid_attributes(program).merge(
          teacher_profile_ids: [teacher.id], student_profile_ids: students.map(&:id)
        )
      }
    end.to change(CourseOffering, :count).by(1)
       .and change(CourseOfferingTeacher, :count).by(1)
       .and change(Enrollment, :count).by(2)

    offering = CourseOffering.order(:id).last
    expect(response).to redirect_to(admin_course_offering_path(offering))
    expect(offering.teacher_profiles).to contain_exactly(teacher)
    expect(offering.enrollments.pluck(:student_profile_id)).to match_array(students.map(&:id))
  end

  it "shows the reference columns and updates assigned teachers without altering enrollments" do
    offering = create(:course_offering)
    first_teacher = create(:teacher_profile, :active, :verified, display_name: "First Teacher")
    second_teacher = create(:teacher_profile, :active, :verified, display_name: "Second Teacher")
    create(:course_offering_teacher, course_offering: offering, teacher_profile: first_teacher, created_by: admin)
    enrollment = create(:enrollment, course_offering: offering)

    patch admin_course_offering_path(offering), params: {
      course_offering: { teacher_profile_ids: [second_teacher.id] }
    }

    expect(response).to redirect_to(admin_course_offering_path(offering))
    expect(offering.reload.teacher_profiles).to contain_exactly(second_teacher)
    expect(offering.enrollments).to contain_exactly(enrollment)

    get admin_course_offerings_path
    expect(response.body).to include(
      I18n.t("course_offerings.madarak.teachers", locale: :ar),
      I18n.t("course_offerings.madarak.students", locale: :ar),
      I18n.t("course_offerings.madarak.schedule", locale: :ar),
      "Second Teacher"
    )
  end

  private

  def valid_attributes(program)
    {
      program_id: program.id, code: "MDRK_COURSE", title_ar: "دورة تجريبية", title_en: "Madarak Course",
      description_ar: "وصف", description_en: "Description", learning_language: "en",
      delivery_mode: "online", target_age_groups: %w[adults], capacity: 12,
      planned_start_on: 1.week.from_now.to_date, planned_end_on: 13.weeks.from_now.to_date,
      default_lesson_duration_minutes: 30, intended_lessons_per_week: 2
    }
  end
end
