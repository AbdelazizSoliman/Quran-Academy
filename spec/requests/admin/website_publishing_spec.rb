require "rails_helper"

RSpec.describe "Admin website publishing" do
  let(:academy_setting) { create(:academy_setting) }
  let(:admin) { create(:user, :admin) }

  before do
    academy_setting
    sign_in admin
  end

  describe "programs" do
    let(:program) { create(:program, :active) }

    it "lists programs with their publication state and links the public settings editor" do
      program

      get admin_website_programs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.website.programs.title"))
      expect(response.body).to include(edit_admin_website_program_path(program))
      expect(response.body).to include(I18n.t("admin.website.programs.states.hidden"))
    end

    it "publishes a program and records an auditable public profile event" do
      expect do
        patch admin_website_program_path(program), params: {
          program: { published: "1", slug_ar: "أساسيات القرآن", slug_en: "Quran Foundations",
                     public_featured: "1", public_display_order: 3 }
        }
      end.to change { program.events.where(event_type: "public_profile_updated").count }.by(1)

      expect(response).to redirect_to(admin_website_programs_path)
      expect(program.reload).to have_attributes(
        published: true, slug_ar: "أساسيات-القرآن", slug_en: "quran-foundations",
        public_featured: true, public_display_order: 3, updated_by: admin
      )
      expect(program.published_at).to be_present
    end

    it "keeps published_at when a program is unpublished" do
      patch admin_website_program_path(program), params: {
        program: { published: "1", slug_ar: "أساسيات", slug_en: "foundations" }
      }
      first_published_at = program.reload.published_at

      patch admin_website_program_path(program), params: { program: { published: "0" } }

      expect(program.reload).to have_attributes(published: false, published_at: first_published_at)
    end

    it "refuses to publish a program with incomplete bilingual public content" do
      program.update!(short_description_en: nil)

      patch admin_website_program_path(program), params: {
        program: { published: "1", slug_ar: "أساسيات", slug_en: "foundations" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(program.reload.published).to be(false)
      expect(response.body).to include(I18n.t("admin.website.programs.errors.title"))
    end

    it "does not let the public settings editor change operational program data" do
      patch admin_website_program_path(program), params: {
        program: { published: "0", code: "HACKED", status: "archived", internal_notes: "changed" }
      }

      expect(program.reload).to have_attributes(status: "active", internal_notes: nil)
      expect(program.code).not_to eq("HACKED")
    end
  end

  describe "fee plans" do
    let(:fee_plan) { create(:fee_plan, name: "Internal Plan") }
    let(:public_presentation) do
      { published: "1", name_ar: "خطة شهرية", name_en: "Monthly Plan",
        description_ar: "وصف", description_en: "Description",
        public_features_ar: "ميزة", public_features_en: "Feature one\nFeature two",
        price_note_en: "Per month", public_cta_label_en: "Join now", public_display_order: 2 }
    end

    it "lists fee plans with their publication state" do
      fee_plan

      get admin_website_fee_plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.website.fee_plans.title"), "Internal Plan")
      expect(response.body).to include(edit_admin_website_fee_plan_path(fee_plan))
    end

    it "publishes localized public presentation for a fee plan" do
      patch admin_website_fee_plan_path(fee_plan), params: { fee_plan: public_presentation }

      expect(response).to redirect_to(admin_website_fee_plans_path)
      expect(fee_plan.reload).to have_attributes(
        published: true, name: "Internal Plan", name_en: "Monthly Plan", name_ar: "خطة شهرية",
        public_display_order: 2, updated_by: admin
      )
      expect(fee_plan.public_features("en")).to eq(["Feature one", "Feature two"])
      expect(fee_plan.published_at).to be_present
    end

    it "refuses to publish a fee plan without a public name in both locales" do
      patch admin_website_fee_plan_path(fee_plan), params: {
        fee_plan: { published: "1", name_ar: "خطة شهرية", name_en: "" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(fee_plan.reload.published).to be(false)
    end

    it "does not let the public settings editor change operational billing data" do
      patch admin_website_fee_plan_path(fee_plan), params: {
        fee_plan: { published: "0", amount: 9_999, tax_percentage: 99, invoice_day: 28, active: "0" }
      }

      expect(fee_plan.reload).to have_attributes(amount: 500, tax_percentage: 0, invoice_day: 7, active: true)
    end
  end

  describe "authorization" do
    %i[staff teacher student].each do |role|
      it "refuses a #{role} account" do
        sign_out admin
        sign_in create(:user, role)

        get admin_website_programs_path
        expect(response).to have_http_status(:forbidden)

        get admin_website_fee_plans_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "redirects an anonymous visitor to sign in" do
      sign_out admin

      get admin_website_programs_path
      expect(response).to redirect_to(new_user_session_path)

      get admin_website_fee_plans_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
