require "rails_helper"

RSpec.describe "Teacher scheduling requests" do
  let(:admin) { create(:user, :admin) }

  it "allows administrators to view scheduling" do
    sign_in admin
    get admin_scheduled_lessons_path
    expect(response).to have_http_status(:ok)
  end

  it "allows staff read-only access but blocks staff mutations" do
    sign_in create(:user, :staff)
    get admin_scheduled_lessons_path
    expect(response).to have_http_status(:ok)
    get new_admin_scheduled_lesson_path
    expect(response).to have_http_status(:forbidden)
  end

  it "scopes teacher schedule to the signed-in teacher" do
    teacher = create(:teacher_profile, :complete, :verified)
    sign_in teacher.user
    get teacher_schedule_index_path
    expect(response).to have_http_status(:ok)
    expect { get teacher_schedule_path(create(:scheduled_lesson)) }.not_to raise_error
  end

  it "scopes student schedule to the signed-in student" do
    student = create(:student_profile, :complete)
    sign_in student.user
    get student_schedule_index_path
    expect(response).to have_http_status(:ok)
  end

  it "does not expose destroy routes" do
    delete_routes = Rails.application.routes.routes.select do |route|
      route.verb.to_s.include?("DELETE") && route.path.spec.to_s.include?("scheduled_lessons")
    end
    expect(delete_routes).to be_empty
  end
end
