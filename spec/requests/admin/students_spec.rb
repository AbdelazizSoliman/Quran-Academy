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

  it "renders the index for every learning status, including at_risk and inactive" do
    StudentProfile::LEARNING_STATUSES.each do |status|
      create(:student_profile, learning_status: status, display_name: "Learner #{status}")
    end

    get admin_students_path

    expect(response).to have_http_status(:ok)
  end

  it "renders the onboarding schedule-slot template with a full weekday select" do
    get new_admin_student_path(locale: "ar")

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    field = document.at_css("template [data-slot-field='weekday']")
    expect(field["class"].split).to include("ds-control")
    expect(field.css("option").map(&:text)).to include("الأحد", "الاثنين", "الثلاثاء")
    expect(field.css("option").map(&:text)).not_to include(*"Translation missing".chars)
    expect(document.at_css("[data-schedule-slots-target='hidden']")).to be_present
  end

  it "creates, updates, verifies, archives, and restores with audits" do
    expect do
      post admin_students_path, params: {
        student_profile: { full_name: "New Learner", email: "new.learner@example.test",
                           country_of_residence: "EG",
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
        student_profile: { full_name: "Dup Learner", email: existing.email }
      }
    end.not_to change(StudentProfile, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "creates an account without an email using an internal placeholder and still creates an invitation" do
    expect do
      expect do
        post admin_students_path, params: { student_profile: { full_name: "NoEmail Learner" } }
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end.to change(StudentProfile, :count).by(1)
    profile = StudentProfile.find_by!(display_name: "NoEmail Learner")
    expect(profile.user.email).to end_with("@no-email.quranacademy.internal")
    # A placeholder email only means no email channel is attempted (students default to
    # account_delivery_method: "whatsapp"); the invitation itself is still created so a WhatsApp
    # attempt is made once the student (or a guardian) has a usable number.
    expect(profile.user.account_invitation).to be_present
  end

  it "still creates and attempts the invitation over WhatsApp for an email-less student with a phone number" do
    post admin_students_path, params: {
      student_profile: { full_name: "WhatsApp Learner", whatsapp_number: "+201234567890" }
    }
    profile = StudentProfile.find_by!(display_name: "WhatsApp Learner")
    expect(profile.user.account_invitation).to be_present
    expect(Notifications::InvitationChannels.call(user: profile.user)).to eq(%w[whatsapp])
  end

  it "splits a single-word name by repeating it as the last name" do
    post admin_students_path, params: { student_profile: { full_name: "Muhammad", email: "muhammad@example.test" } }
    profile = User.find_by!(email: "muhammad@example.test").student_profile
    expect(profile.user.first_name).to eq("Muhammad")
    expect(profile.user.last_name).to eq("Muhammad")
  end

  it "reuses an existing guardian with a matching phone number instead of creating a duplicate" do
    guardian = create(:guardian, phone_number: "+201001234567")
    expect do
      post admin_students_path, params: {
        student_profile: { full_name: "Sibling Learner", guardian_name: "Someone Else",
                           guardian_phone_country_code: "EG", guardian_phone: "1001234567" }
      }
    end.not_to change(Guardian, :count)
    profile = StudentProfile.find_by!(display_name: "Sibling Learner")
    expect(profile.guardians).to contain_exactly(guardian)
  end

  it "creates an authoritative enrollment schedule and slots from onboarding metadata" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    offering = create(:course_offering, :open, planned_start_on: Date.current)
    slots = [{ weekday: "sunday", time: "18:00" }, { weekday: "tuesday", time: "19:30" }]

    expect do
      post admin_students_path, params: {
        student_profile: {
          full_name: "Scheduled Learner", email: "scheduled@example.test",
          assigned_teacher_profile_id: teacher.id,
          course_offering_id: offering.id, lesson_duration_minutes: 45, weekly_lesson_count: 2,
          slots_json: slots.to_json
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
    slots = [{ weekday: Date.current.strftime("%A").downcase, time: "18:00" }]

    post admin_students_path, params: {
      student_profile: {
        full_name: "Conflict Learner", email: "conflict@example.test",
        assigned_teacher_profile_id: teacher.id, course_offering_id: offering.id,
        lesson_duration_minutes: 45, slots_json: slots.to_json
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

  it "shows only active fee plans in the onboarding fee plan dropdown" do
    active_plan = create(:fee_plan, name: "Active Plan")
    inactive_plan = create(:fee_plan, :inactive, name: "Inactive Plan")

    get new_admin_student_path

    expect(response.body).to include(active_plan.name)
    expect(response.body).not_to include(inactive_plan.name)
  end

  it "creates a student with a selected fee plan, independent of any course offering" do
    fee_plan = create(:fee_plan)
    post admin_students_path, params: {
      student_profile: { full_name: "Plan Learner", email: "plan.learner@example.test", fee_plan_id: fee_plan.id }
    }
    profile = StudentProfile.find_by!(display_name: "Plan Learner")
    expect(profile.fee_plan).to eq(fee_plan)
    expect(profile.course_offerings).to be_empty
  end

  it "generates real scheduled lessons for a fee-plan-only student with no program, offering, or enrollment" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    weekday = Date.current.strftime("%A").downcase
    create(:teacher_availability, teacher_profile: teacher, weekday:, starts_at_local: "09:00",
                                  ends_at_local: "21:00", time_zone: "Cairo",
                                  effective_from: Date.current - 1.week, availability_type: "teaching")
    fee_plan = create(:fee_plan)
    slots = [{ weekday:, time: "10:00" }]

    expect do
      post admin_students_path, params: {
        student_profile: {
          full_name: "Direct Learner", email: "direct.learner@example.test",
          assigned_teacher_profile_id: teacher.id, fee_plan_id: fee_plan.id,
          lesson_duration_minutes: 30, weekly_lesson_count: 1, schedule_generation_weeks: 4,
          slots_json: slots.to_json
        }
      }
    end.to change(ScheduledLesson, :count).by_at_least(1)

    profile = StudentProfile.find_by!(display_name: "Direct Learner")
    expect(profile.enrollments).to be_empty
    expect(Program.count).to eq(0)
    expect(CourseOffering.count).to eq(0)

    schedule = profile.direct_lesson_schedules.first
    expect(schedule).to be_present
    expect(schedule.enrollment).to be_nil
    expect(schedule.teacher_profile).to eq(teacher)

    lesson = profile.scheduled_lessons.first
    expect(lesson.course_offering_id).to be_nil
    expect(lesson.teacher_profile).to eq(teacher)
    expect(lesson).to be_scheduled

    participation = lesson.scheduled_lesson_enrollments.first
    expect(participation.enrollment_id).to be_nil
    expect(participation.student_profile).to eq(profile)

    get admin_scheduled_lessons_path(week: lesson.starts_at.to_date.beginning_of_week(:sunday).iso8601)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.display_name)

    sign_out admin
    sign_in teacher.user
    get teacher_schedule_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.display_name)

    sign_out teacher.user
    profile.user.update!(status: "active")
    sign_in profile.user
    get student_schedule_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.display_name)
  end

  it "records a granular reason_code and message when the teacher has no online_meeting_url" do
    teacher = create(:teacher_profile, :active, :verified, online_meeting_url: nil)
    weekday = Date.current.strftime("%A").downcase
    create(:teacher_availability, teacher_profile: teacher, weekday:, starts_at_local: "09:00",
                                  ends_at_local: "21:00", time_zone: "Cairo",
                                  effective_from: Date.current - 1.week, availability_type: "teaching")
    fee_plan = create(:fee_plan)
    slots = [{ weekday:, time: "10:00" }]

    expect do
      post admin_students_path, params: {
        student_profile: {
          full_name: "Unreachable Teacher Learner", email: "unreachable.teacher@example.test",
          assigned_teacher_profile_id: teacher.id, fee_plan_id: fee_plan.id,
          lesson_duration_minutes: 30, weekly_lesson_count: 1, schedule_generation_weeks: 4,
          slots_json: slots.to_json
        }
      }
    end.not_to change(ScheduledLesson, :count)

    profile = StudentProfile.find_by!(display_name: "Unreachable Teacher Learner")
    schedule = profile.direct_lesson_schedules.first
    expect(schedule).to be_present

    issue = schedule.generation_issues.unresolved.first
    expect(issue).to be_present
    expect(issue.reason_code).to eq("online_meeting_url_required")
    expect(issue.details["attributes"]).to include("online_meeting_url")
    expect(issue.details["reason_codes"]).to eq(["required"])
    expect(issue.details["messages"]).to be_present
  end

  it "shows no generation warning when every lesson occurrence is generated successfully" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    weekday = Date.current.strftime("%A").downcase
    create(:teacher_availability, teacher_profile: teacher, weekday:, starts_at_local: "09:00",
                                  ends_at_local: "21:00", time_zone: "Cairo",
                                  effective_from: Date.current - 1.week, availability_type: "teaching")
    fee_plan = create(:fee_plan)

    post admin_students_path, params: {
      student_profile: {
        full_name: "Fully Scheduled Learner", email: "fully.scheduled@example.test",
        assigned_teacher_profile_id: teacher.id, fee_plan_id: fee_plan.id,
        lesson_duration_minutes: 30, weekly_lesson_count: 1, schedule_generation_weeks: 1,
        slots_json: [{ weekday:, time: "10:00" }].to_json
      }
    }

    profile = StudentProfile.find_by!(display_name: "Fully Scheduled Learner")
    expect(response).to redirect_to(admin_student_path(profile))
    expect(flash[:warning]).to be_nil
  end

  it "warns clearly, without failing student creation, when lesson generation fails for every occurrence" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher")
    fee_plan = create(:fee_plan)
    weekday = Date.current.strftime("%A").downcase

    expect do
      post admin_students_path, params: {
        student_profile: {
          full_name: "Unavailable Teacher Learner", email: "unavailable.teacher.learner@example.test",
          assigned_teacher_profile_id: teacher.id, fee_plan_id: fee_plan.id,
          lesson_duration_minutes: 30, weekly_lesson_count: 1, schedule_generation_weeks: 1,
          slots_json: [{ weekday:, time: "10:00" }].to_json
        }
      }
    end.to change(StudentProfile, :count).by(1)

    profile = StudentProfile.find_by!(display_name: "Unavailable Teacher Learner")
    expect(response).to redirect_to(admin_student_path(profile))
    expect(flash[:warning]).to be_present
    expect(flash[:warning]).to include("Teacher unavailable")
    expect(ScheduledLesson.where(teacher_profile: teacher)).to be_empty
    expect(profile.direct_lesson_schedules.first.generation_issues.unresolved).not_to be_empty
  end

  it "creates a student with no fee plan selected" do
    post admin_students_path, params: {
      student_profile: { full_name: "Planless Learner", email: "planless.learner@example.test" }
    }
    profile = StudentProfile.find_by!(display_name: "Planless Learner")
    expect(profile.fee_plan_id).to be_nil
  end

  it "shows the currently assigned fee plan selected when editing, changes it, and can remove it" do
    plan_one = create(:fee_plan, name: "Plan One")
    plan_two = create(:fee_plan, name: "Plan Two")
    profile = create(:student_profile, user: student_user, fee_plan: plan_one)

    get edit_admin_student_path(profile)
    document = Nokogiri::HTML(response.body)
    selected = document.at_css("select#student_profile_fee_plan_id option[selected]")
    expect(selected&.attr("value")).to eq(plan_one.id.to_s)

    patch admin_student_path(profile), params: { student_profile: { fee_plan_id: plan_two.id } }
    expect(profile.reload.fee_plan).to eq(plan_two)

    patch admin_student_path(profile), params: { student_profile: { fee_plan_id: "" } }
    expect(profile.reload.fee_plan_id).to be_nil
  end

  it "shows and persists teacher, schedule, and price fields on the edit page" do
    teacher = create(:teacher_profile, :active, :verified, display_name: "Sheikh Ahmed")
    profile = create(:student_profile, user: student_user, assigned_teacher_profile: teacher,
                                       lesson_duration_minutes: 30, weekly_lesson_count: 2,
                                       schedule_slots: [{ "weekday" => "sunday", "time" => "18:00",
                                                          "duration" => "30", "subject" => "حفظ" }])

    get edit_admin_student_path(profile)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("student_profiles.sections.teacher_curriculum", locale: :ar),
                                     I18n.t("student_profiles.sections.schedule_price", locale: :ar))
    document = Nokogiri::HTML(response.body)
    selected_teacher = document.at_css("select#student_profile_assigned_teacher_profile_id option[selected]")
    expect(selected_teacher&.text).to eq("Sheikh Ahmed")
    expect(document.at_css("#student_profile_lesson_duration_minutes")["value"]).to eq("30")
    expect(document.at_css("select[data-slot-field='weekday'] option[selected]")["value"]).to eq("sunday")

    new_teacher = create(:teacher_profile, :active, :verified)
    slots = [{ weekday: "tuesday", time: "19:00", duration: "45", subject: "تجويد" }]
    patch admin_student_path(profile), params: {
      student_profile: {
        assigned_teacher_profile_id: new_teacher.id, lesson_duration_minutes: 45, weekly_lesson_count: 3,
        weekly_price: 100, billing_currency: "EGP", slots_json: slots.to_json
      }
    }

    profile.reload
    expect(response).to redirect_to(admin_student_path(profile))
    expect(profile.assigned_teacher_profile).to eq(new_teacher)
    expect(profile.lesson_duration_minutes).to eq(45)
    expect(profile.weekly_lesson_count).to eq(3)
    expect(profile.weekly_price).to eq(100)
    expect(profile.schedule_slots).to eq(
      [{ "weekday" => "tuesday", "time" => "19:00", "duration" => "45", "subject" => "تجويد" }]
    )
    expect(profile.schedule_weekday).to eq("tuesday")
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
