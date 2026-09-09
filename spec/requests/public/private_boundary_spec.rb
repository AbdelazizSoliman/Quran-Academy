require "rails_helper"

RSpec.describe "Public and private boundary" do
  {
    dashboard: -> { dashboard_path },
    admin: -> { admin_users_path },
    student: -> { student_schedule_index_path },
    teacher: -> { teacher_schedule_index_path },
    guardian: -> { guardian_students_path },
    program_admin: -> { admin_programs_path },
    program_publishing: -> { admin_website_programs_path },
    fee_plan_admin: -> { admin_fee_plans_path },
    fee_plan_publishing: -> { admin_website_fee_plans_path },
    public_website_settings: -> { edit_admin_public_website_path },
    course_offerings: -> { admin_course_offerings_path },
    enrollments: -> { admin_enrollments_path },
    scheduled_lessons: -> { admin_scheduled_lessons_path },
    invoices: -> { admin_finance_invoices_path }
  }.each do |area, path|
    it "does not allow an anonymous visitor into the #{area} area" do
      get instance_exec(&path)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "keeps operational catalog records out of the public catalog pages" do
    academy_setting = create(:academy_setting)
    create(:public_website_setting, academy_setting:)
    program = create(:program, :published, internal_notes: "Internal only note")
    fee_plan = create(:fee_plan, :published)

    [public_programs_path(locale: :en), public_fees_path(locale: :en),
     public_program_path(locale: :en, slug: program.slug_en), localized_public_home_path(locale: :en)].each do |path|
      get path

      expect(response.body).not_to include("Internal only note", program.public_id, fee_plan.public_id)
      expect(response.body).not_to include(admin_programs_path, admin_fee_plans_path, dashboard_path)
    end
  end
end
