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
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('dir="ltr"')
  end

  it "shows only valid program lifecycle actions" do
    program = create(:program, :active)
    sign_in admin

    get admin_program_path(program)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(activate_admin_program_path(program))
    expect(response.body).to include(deactivate_admin_program_path(program))
  end

  it "shows only offering transitions valid for each current status" do
    sign_in admin

    {
      draft: { open: true }, open: { open: false }, in_progress: { open: false }, completed: { open: false }
    }.each do |status, expectations|
      offering = create(:course_offering, status:, accepts_new_enrollments: status == :open)
      get admin_course_offering_path(offering)

      expect(response).to have_http_status(:ok)
      expect(response.body.include?(open_admin_course_offering_path(offering))).to eq(expectations[:open])
    end
  end

  it "hides enrollment approval when the offering is no longer accepting enrollments" do
    offering = create(:course_offering, :open)
    offering.update!(status: "in_progress", accepts_new_enrollments: false)
    enrollment = create(:enrollment, course_offering: offering, status: "waitlisted")
    sign_in admin

    get admin_enrollment_path(enrollment)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(approve_admin_enrollment_path(enrollment))
    expect(response.body).to include(I18n.t("enrollments.approval_unavailable.title", locale: :ar))
  end

  it "creates a program without permitting lifecycle status" do
    sign_in admin
    post admin_programs_path, params: { program: attributes_for(:program).merge(status: "active") }
    expect(response).to have_http_status(:see_other)
    expect(Program.last).to be_draft
  end

  it "activates a valid program and then opens its offering" do
    program = create(:program)
    offering = create(:course_offering, program:)
    sign_in admin

    patch activate_admin_program_path(program)
    expect(response).to have_http_status(:see_other)
    expect(program.reload).to be_active

    patch open_admin_course_offering_path(offering)
    expect(response).to have_http_status(:see_other)
    expect(offering.reload).to be_open
  end

  it "redirects with the validation reason when opening an offering for an inactive program" do
    offering = create(:course_offering, program: create(:program))
    sign_in admin

    patch open_admin_course_offering_path(offering)

    expect(response).to redirect_to(admin_course_offering_path(offering))
    expect(flash[:alert]).to be_present
    expect(offering.reload).to be_draft
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

  it "shows approval validation errors instead of appearing unchanged" do
    offering = create(:course_offering, :open, capacity: 1)
    create(:enrollment, :approved, course_offering: offering)
    enrollment = create(:enrollment, course_offering: offering)
    sign_in admin

    patch approve_admin_enrollment_path(enrollment)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("forms.errors_title", locale: :ar))
    expect(response.body).to include(I18n.t("errors.messages.capacity_full", locale: :ar))
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
