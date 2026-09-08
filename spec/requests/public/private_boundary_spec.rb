require "rails_helper"

RSpec.describe "Public and private boundary" do
  {
    dashboard: -> { dashboard_path },
    admin: -> { admin_users_path },
    student: -> { student_schedule_index_path },
    teacher: -> { teacher_schedule_index_path },
    guardian: -> { guardian_students_path }
  }.each do |area, path|
    it "does not allow an anonymous visitor into the #{area} area" do
      get instance_exec(&path)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
