require "rails_helper"

RSpec.describe "Madarak-matching admin students" do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "filters by teacher, country, gender, level, and age group" do
    teacher = create(:teacher_profile)
    matching = create(:student_profile, assigned_teacher_profile: teacher, country_of_residence: "EG",
                                         gender: "female", current_quran_level: "intermediate",
                                         date_of_birth: 15.years.ago.to_date)
    hidden = create(:student_profile, country_of_residence: "US", gender: "male",
                                       current_quran_level: "beginner", date_of_birth: 25.years.ago.to_date)

    get admin_students_path, params: {
      teacher_id: teacher.id, country: "EG", gender: "female",
      current_quran_level: "intermediate", age_group: "13_17"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.public_id)
    expect(response.body).not_to include(hidden.public_id)
  end

  it "exports the currently filtered student data as an Excel-compatible CSV" do
    profile = create(:student_profile, country_of_residence: "EG")
    create(:student_profile, country_of_residence: "US")

    get export_admin_students_path, params: { country: "EG" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include(profile.public_id, "public_id")
  end

  it "imports students through the normal onboarding workflow" do
    file = Tempfile.new(["students", ".csv"])
    file.write("first_name,last_name,email,display_name,learning_status,country_of_residence,current_quran_level\n")
    file.write("Imported,Student,imported.student@example.test,Imported Student,active,EG,beginner\n")
    file.rewind
    upload = Rack::Test::UploadedFile.new(file.path, "text/csv")

    expect do
      post import_admin_students_path, params: { file: upload }
    end.to change(StudentProfile, :count).by(1)

    expect(response).to redirect_to(admin_students_path)
    expect(StudentProfile.find_by!(display_name: "Imported Student").learning_status).to eq("active")
  ensure
    file&.close!
  end
end
