require "rails_helper"

RSpec.describe "Teacher assessments" do
  let(:teacher) do
    create(:teacher_profile, :active, :verified,
           user: create(:user, :teacher, status: "active"))
  end

  before { sign_in teacher.user }

  it "renders the new assessment form using the aliased teacher route" do
    get new_teacher_assessment_path

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css("form")&.attr("action")).to eq(teacher_assessments_path)
  end
end
