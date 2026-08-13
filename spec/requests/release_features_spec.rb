require "rails_helper"

RSpec.describe "Release feature boundaries" do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "returns not found for a disabled deferred module" do
    original = ENV["FEATURE_EXAMS"]
    ENV["FEATURE_EXAMS"] = "false"

    get admin_exam_sessions_path

    expect(response).to have_http_status(:not_found)
  ensure
    original.nil? ? ENV.delete("FEATURE_EXAMS") : ENV["FEATURE_EXAMS"] = original
  end
end
