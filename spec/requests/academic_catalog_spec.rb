require "rails_helper"

RSpec.describe "Academic catalog requests" do
  let(:admin) { create(:user, :admin) }

  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "protects administration from unauthenticated and non-admin users" do
    get admin_programs_path
    expect(response).to redirect_to(new_user_session_path)
    sign_in create(:user, :teacher)
    get admin_programs_path
    expect(response).to have_http_status(:forbidden)
  end

  it "renders localized admin catalog pages in both directions" do
    sign_in admin
    get admin_programs_path, params: { locale: "ar" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('dir="rtl"', "البرامج")
    admin.update!(preferred_locale: "en")
    get admin_course_offerings_path
    expect(response.body).to include('dir="ltr"', "Course Offerings")
  end

  it "creates a program without permitting lifecycle status" do
    sign_in admin
    post admin_programs_path, params: { program: attributes_for(:program).merge(status: "active") }
    expect(response).to have_http_status(:see_other)
    expect(Program.last).to be_draft
  end

  it "keeps student enrollment pages ownership scoped and hides internal notes" do
    student = create(:student_profile, :complete)
    own = create(:enrollment, student_profile: student, administrator_notes: "secret")
    other = create(:enrollment)
    sign_in student.user
    get student_enrollment_path(own)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("secret")
    get student_enrollment_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "does not expose destructive or public enrollment routes" do
    delete admin_program_path(create(:program))
    expect(response).to have_http_status(:not_found)
    delete admin_course_offering_path(create(:course_offering))
    expect(response).to have_http_status(:not_found)
    delete admin_enrollment_path(create(:enrollment))
    expect(response).to have_http_status(:not_found)
    expect(Rails.application.routes.named_routes.names).not_to include(:new_student_enrollment)
  end
end
