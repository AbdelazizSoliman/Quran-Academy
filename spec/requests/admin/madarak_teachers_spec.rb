require "rails_helper"

RSpec.describe "Madarak-matching admin teachers" do
  let(:admin) { create(:user, :admin) }

  before do
    AcademySetting.current.update!(teaching_languages: %w[ar en])
    sign_in admin
  end

  it "renders the reference columns and filters by gender, country, and specialization" do
    matching = create(:teacher_profile, display_name: "Matching Teacher", gender: "female",
                                        country_of_residence: "EG",
                                        teaching_specializations: %w[tajweed])
    hidden = create(:teacher_profile, display_name: "Hidden Teacher", gender: "male",
                                      country_of_residence: "US",
                                      teaching_specializations: %w[arabic])

    get admin_teachers_path, params: { gender: "female", country: "EG", specialization: "tajweed" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.public_id, I18n.t("teachers.madarak.utilization", locale: :ar),
                                     I18n.t("teachers.madarak.assigned_students", locale: :ar))
    expect(response.body).not_to include(hidden.public_id)
  end

  it "exports the currently filtered teacher data as an Excel-compatible CSV" do
    profile = create(:teacher_profile, country_of_residence: "EG")
    create(:teacher_profile, country_of_residence: "US")

    get export_admin_teachers_path, params: { country: "EG" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include(profile.public_id, "utilization_percentage", "assigned_students")
  end

  it "imports teachers through the normal onboarding workflow" do
    file = Tempfile.new(["teachers", ".csv"])
    file.write("first_name,last_name,email,display_name,employment_status,work_days,work_start_time,work_end_time\n")
    file.write("Imported,Teacher,imported.teacher@example.test,Imported Teacher,active,sunday;wednesday,09:00,14:00\n")
    file.rewind
    upload = Rack::Test::UploadedFile.new(file.path, "text/csv")

    expect do
      post import_admin_teachers_path, params: { file: upload }
    end.to change(TeacherProfile, :count).by(1)

    expect(response).to redirect_to(admin_teachers_path)
    profile = TeacherProfile.find_by!(display_name: "Imported Teacher")
    expect(profile).to have_attributes(employment_status: "active", work_days: %w[sunday wednesday])
  ensure
    file&.close!
  end
end
