require "rails_helper"

RSpec.describe "Admin students" do
  let(:admin) { create(:user, :admin) }
  let(:student_user) { create(:user, :student) }

  before { sign_in admin }

  it "lists, searches, and renders both directions" do
    profile = create(:student_profile, user: student_user, display_name: "Search Learner")
    get admin_students_path, params: { q: "Search", locale: "ar" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.public_id, 'dir="rtl"')
    get admin_students_path, params: { locale: "en" }
    expect(response.body).to include('dir="ltr"')
  end

  it "creates, updates, verifies, archives, and restores with audits" do
    expect do
      post admin_students_path, params: {
        student_profile: { first_name: "New", last_name: "Learner", email: "new.learner@example.test",
                           display_name: "New Learner", country_of_residence: "EG",
                           preferred_learning_language: "en", learning_goals: "Read fluently" }
      }
    end.to change(StudentProfile, :count).by(1)
    profile = StudentProfile.find_by!(display_name: "New Learner")
    expect(response).to redirect_to(admin_student_path(profile))
    patch admin_student_path(profile), params: { student_profile: { display_name: "Updated Student" } }
    patch verify_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("verified")
    patch archive_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("archived")
    patch restore_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("draft")
    expect(profile.events.count).to eq(5)
  end

  it "rejects onboarding with a duplicate email without creating a profile" do
    existing = create(:user, :student, email: "taken@example.test")
    expect do
      post admin_students_path, params: {
        student_profile: { first_name: "Dup", last_name: "Learner", email: existing.email }
      }
    end.not_to change(StudentProfile, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "creates an authoritative enrollment schedule and slots from onboarding metadata" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    offering = create(:course_offering, :open, planned_start_on: Date.current)

    expect do
      post admin_students_path, params: {
        student_profile: {
          first_name: "Scheduled", last_name: "Learner", email: "scheduled@example.test",
          display_name: "Scheduled Learner", assigned_teacher_profile_id: teacher.id,
          course_offering_id: offering.id, lesson_duration_minutes: 45, weekly_lesson_count: 2,
          schedule_weekday_1: "sunday", schedule_time_1: "18:00",
          schedule_weekday_2: "tuesday", schedule_time_2: "19:30"
        }
      }
    end.to change(EnrollmentLessonSchedule, :count).by(1)

    profile = StudentProfile.find_by!(display_name: "Scheduled Learner")
    schedule = profile.enrollments.first.lesson_schedules.first
    expect(schedule.teacher_profile).to eq(teacher)
    expect(schedule.lesson_duration_minutes).to eq(45)
    expect(schedule.slots.pluck(:weekday)).to contain_exactly("sunday", "tuesday")
    expect(profile.schedule_slots.size).to eq(2)
  end

  it "keeps onboarding committed when initial occurrence generation reports a conflict" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    offering = create(:course_offering, :open, planned_start_on: Date.current)

    post admin_students_path, params: {
      student_profile: {
        first_name: "Conflict", last_name: "Learner", email: "conflict@example.test",
        assigned_teacher_profile_id: teacher.id, course_offering_id: offering.id,
        lesson_duration_minutes: 45, schedule_weekday_1: Date.current.strftime("%A").downcase,
        schedule_time_1: "18:00"
      }
    }

    expect(response).to have_http_status(:see_other)
    profile = User.find_by!(email: "conflict@example.test").student_profile
    expect(profile).to be_persisted
    expect(profile.enrollments.first.lesson_schedules.first.generation_issues).not_to be_empty
  end

  it "excludes ownership, public IDs, lifecycle status, actors, and metadata from strong parameters" do
    profile = create(:student_profile, user: student_user)
    other = create(:user, :student)
    patch admin_student_path(profile), params: {
      student_profile: { display_name: "Allowed", user_id: other.id, public_id: "STD-HACKED0000",
                         profile_status: "verified", updated_by_id: other.id, metadata: { password: "x" } }
    }
    profile.reload
    expect(profile.user).to eq(student_user)
    expect(profile.public_id).not_to eq("STD-HACKED0000")
    expect(profile.profile_status).to eq("draft")
  end

  it "redirects unauthenticated users and forbids non-admin roles" do
    sign_out admin
    get admin_students_path
    expect(response).to redirect_to(new_user_session_path)
    %i[staff teacher student].each do |role|
      sign_in create(:user, role)
      get admin_students_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end
end
