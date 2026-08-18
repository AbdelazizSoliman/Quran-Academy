require "rails_helper"

RSpec.describe "Admin teacher profiles" do
  let(:admin) { create(:user, :admin) }
  let(:teacher_user) { create(:user, :teacher) }

  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "redirects unauthenticated access and forbids non-admin roles" do
    get admin_teachers_path
    expect(response).to redirect_to(new_user_session_path)

    %i[staff teacher student].each do |role|
      sign_in create(:user, role)
      get admin_teachers_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end

  it "does not authenticate inactive administrators" do
    %i[pending suspended disabled].each do |status|
      sign_in create(:user, :admin, status)
      get admin_teachers_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "renders localized index, filters, sorting, pagination-compatible links, and empty state" do
    sign_in admin
    get admin_teachers_path
    expect(response.body).to include('dir="rtl"', "لا توجد ملفات معلّمين")

    create(:teacher_profile, user: teacher_user, display_name: "Search Teacher")
    admin.update!(preferred_locale: "en")
    get admin_teachers_path, params: { q: "Search", employment_status: "candidate", sort: "name" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('dir="ltr"', "Search Teacher", "Teacher profiles")
    expect(response.body).not_to include("translation missing")
  end

  it "creates a teacher account and profile via onboarding and records audit" do
    sign_in admin
    expect do
      post admin_teachers_path, params: {
        teacher_profile: { first_name: "New", last_name: "Teacher", email: "new.teacher@example.test",
                           display_name: "New Teacher", employment_status: "active" }
      }
    end.to change(TeacherProfile, :count).by(1)

    profile = TeacherProfile.find_by!(display_name: "New Teacher")
    expect(response).to redirect_to(admin_teacher_path(profile))
    expect(profile.public_id).to start_with("TCH-")
    expect(profile.events.pluck(:event_type)).to eq(%w[created])
  end

  it "combines the isolated phone and WhatsApp country codes with the local number on onboarding" do
    sign_in admin
    post admin_teachers_path, params: {
      teacher_profile: { first_name: "Coded", last_name: "Teacher", email: "coded.teacher@example.test",
                         display_name: "Coded Teacher", employment_status: "active",
                         phone_number_country_code: "EG", phone_number: "1001234567",
                         whatsapp_number_country_code: "SA", whatsapp_number: "501234567" }
    }

    profile = TeacherProfile.find_by!(display_name: "Coded Teacher")
    expect(profile.phone_number).to eq("+201001234567")
    expect(profile.whatsapp_number).to eq("+966501234567")
  end

  it "defaults onboarding and availability to the academy timezone and accepts a teacher override" do
    AcademySetting.current.update!(default_time_zone: "Riyadh")
    sign_in admin
    post admin_teachers_path, params: {
      teacher_profile: { first_name: "Riyadh", last_name: "Teacher", email: "riyadh@example.test",
                         display_name: "Riyadh Teacher", employment_status: "active", time_zone: "Riyadh",
                         work_days: %w[sunday], work_start_time: "09:00", work_end_time: "17:00" }
    }

    profile = TeacherProfile.find_by!(display_name: "Riyadh Teacher")
    expect(profile.user.time_zone).to eq("Riyadh")
    expect(profile.availabilities.sole.time_zone).to eq("Riyadh")

    post admin_teachers_path, params: {
      teacher_profile: { first_name: "Default", last_name: "Teacher", email: "default-zone@example.test",
                         display_name: "Default Zone Teacher", employment_status: "candidate" }
    }
    expect(TeacherProfile.find_by!(display_name: "Default Zone Teacher").user.time_zone).to eq("Riyadh")
  end

  it "stores a default meeting URL during onboarding and exposes the field for editing" do
    sign_in admin
    post admin_teachers_path, params: {
      teacher_profile: {
        first_name: "Meeting", last_name: "Teacher", email: "meeting.teacher@example.test",
        display_name: "Meeting Teacher", employment_status: "active",
        online_meeting_url: "https://meet.example.test/fixed-room"
      }
    }

    profile = TeacherProfile.find_by!(display_name: "Meeting Teacher")
    expect(profile.online_meeting_url).to eq("https://meet.example.test/fixed-room")

    get edit_admin_teacher_path(profile)
    expect(response.body).to include("teacher_profile_online_meeting_url",
                                     I18n.t("teacher_profiles.form.online_meeting_url_hint", locale: :ar))
  end

  it "shows working start/end time fields on the edit page, preselected with existing values" do
    profile = create(:teacher_profile, user: teacher_user, work_days: %w[sunday thursday],
                                       work_start_time: "09:00", work_end_time: "17:00")
    sign_in admin

    get edit_admin_teacher_path(profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("teacher_profiles.fields.work_start_time", locale: :ar),
                                     I18n.t("teacher_profiles.fields.work_end_time", locale: :ar))
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#teacher_profile_work_start_time")["value"]).to start_with("09:00")
    expect(document.at_css("#teacher_profile_work_end_time")["value"]).to start_with("17:00")
    expect(document.at_css("input[name='teacher_profile[work_days][]'][value='sunday']")["checked"]).to eq("checked")
    expect(document.at_css("input[name='teacher_profile[work_days][]'][value='monday']")["checked"]).to be_nil
  end

  it "persists edited working days and hours, and allows clearing them for all-day availability" do
    profile = create(:teacher_profile, user: teacher_user, employment_status: "active")
    sign_in admin

    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(work_days: %w[thursday], work_start_time: "09:00",
                                              work_end_time: "17:00")
    }

    profile.reload
    expect(profile.work_days).to eq(%w[thursday])
    expect(profile.work_start_time.strftime("%H:%M")).to eq("09:00")
    expect(profile.work_end_time.strftime("%H:%M")).to eq("17:00")

    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(work_days: %w[thursday], work_start_time: "", work_end_time: "")
    }

    profile.reload
    expect(profile.work_days).to eq(%w[thursday])
    expect(profile.work_start_time).to be_nil
    expect(profile.work_end_time).to be_nil

    starts_at = Time.find_zone!("Cairo").local(2026, 8, 13, 22, 0)
    result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: profile, starts_at:,
                                                       ends_at: starts_at + 30.minutes)
    expect(result.available?).to be(true)
  end

  it "rejects providing only one working time on update" do
    profile = create(:teacher_profile, user: teacher_user)
    sign_in admin

    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(work_days: %w[thursday], work_start_time: "09:00",
                                              work_end_time: "")
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(profile.reload.work_start_time).to be_nil
  end

  it "redacts the complete meeting URL from teacher profile audit metadata" do
    profile = create(:teacher_profile, user: teacher_user)
    sign_in admin

    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(online_meeting_url: "https://meet.example.test/secret?token=value")
    }

    expect(profile.reload.online_meeting_url).to eq("https://meet.example.test/secret?token=value")
    expect(profile.events.last.metadata.to_s).to include("[FILTERED]")
    expect(profile.events.last.metadata.to_s).not_to include("meet.example.test", "token=value")
  end

  it "rejects onboarding with a duplicate email without creating a profile" do
    existing = create(:user, :teacher, email: "taken.teacher@example.test")
    sign_in admin
    expect do
      post admin_teachers_path, params: {
        teacher_profile: { first_name: "Dup", last_name: "Teacher", email: existing.email }
      }
    end.not_to change(TeacherProfile, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "shows compensation, internal notes, readable catalogs, audit, and user link to admins" do
    profile = create(:teacher_profile, user: teacher_user, internal_notes: "Administrator only")
    create(:teacher_profile_event, teacher_profile: profile, actor: admin)
    sign_in admin
    get admin_teacher_path(profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Administrator only", "100.0", "العربية", admin.full_name)
    expect(response.body).not_to include(profile.teaching_languages.inspect, "translation missing")
  end

  it "shows the teacher's recurring availability and a preselected creation link" do
    profile = create(:teacher_profile, user: teacher_user, employment_status: "active")
    availability = create(
      :teacher_availability, teacher_profile: profile, weekday: "monday",
                             starts_at_local: "09:00", ends_at_local: "12:00"
    )
    sign_in admin
    get admin_teacher_path(profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("الإتاحة المتكررة", "الاثنين", "09:00", "12:00", availability.time_zone)
    expect(response.body).to include(admin_teacher_availability_path(availability))
    expect(response.body).to include(new_admin_teacher_availability_path(teacher_profile_id: profile.id))
  end

  it "updates profile fields but protects ownership, public ID, status, and audit metadata" do
    profile = create(:teacher_profile, user: teacher_user)
    original_id = profile.public_id
    sign_in admin
    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(
        display_name: "Changed", public_id: "HACK", user_id: create(:user, :teacher).id,
        profile_status: "verified", metadata: { password: "secret" }
      )
    }

    expect(response).to redirect_to(admin_teacher_path(profile))
    expect(profile.reload.attributes.values_at("display_name", "public_id", "profile_status", "user_id"))
      .to eq(["Changed", original_id, "draft", teacher_user.id])
    expect(profile.events.last.metadata.to_s).not_to match(/password|secret/)
  end

  it "renders invalid values without audit and preserves submitted safe values" do
    profile = create(:teacher_profile, user: teacher_user)
    sign_in admin
    patch admin_teacher_path(profile), params: {
      teacher_profile: valid_attributes.merge(display_name: "Retained", default_lesson_rate: -2,
                                              teaching_languages: %w[xx])
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Retained")
    expect(profile.events).to be_empty
  end

  it "verifies, archives, and restores without exposing destroy routes" do
    profile = create(:teacher_profile, :complete, user: teacher_user)
    sign_in admin
    patch verify_admin_teacher_path(profile)
    expect(profile.reload.profile_status).to eq("verified")
    patch archive_admin_teacher_path(profile)
    expect(profile.reload.profile_status).to eq("archived")
    patch restore_admin_teacher_path(profile)
    expect(profile.reload.profile_status).to eq("draft")
    delete admin_teacher_path(profile)
    expect(response).to have_http_status(:not_found)
  end

  it "prevents user administration from changing a profiled teacher role" do
    profile = create(:teacher_profile, user: teacher_user)
    sign_in admin
    patch admin_user_path(teacher_user), params: {
      user: {
        first_name: teacher_user.first_name, last_name: teacher_user.last_name,
        email: teacher_user.email, role: "staff",
        preferred_locale: teacher_user.preferred_locale, time_zone: teacher_user.time_zone
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(teacher_user.reload).to be_teacher
    expect(profile.reload.user).to eq(teacher_user)
  end

  def valid_attributes
    attributes_for(:teacher_profile).except(:user)
  end
end
