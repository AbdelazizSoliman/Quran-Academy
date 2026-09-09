require "rails_helper"

RSpec.describe "Public inquiries" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  def trial_params
    { name: " آمنة حسن ", phone: "01012345678", email: "amina@example.test",
      student_age: 12, preferred_schedule_notes: "بعد الظهر", message: "أرغب في التجربة" }
  end

  describe "trial requests" do
    it "renders Arabic and English forms with the correct direction" do
      get public_trial_path(locale: :ar)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<html lang="ar" dir="rtl">', I18n.t("public.trial.title", locale: :ar))

      get public_trial_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<html lang="en" dir="ltr">', I18n.t("public.trial.title", locale: :en))
    end

    it "creates only a lightweight lead and captures the route locale" do
      original_counts = [User.count, StudentProfile.count, Enrollment.count]

      expect do
        post public_trial_path(locale: :ar), params: { public_inquiry: trial_params }
      end.to change(PublicInquiry, :count).by(1)

      expect(response).to have_http_status(:created)
      expect([User.count, StudentProfile.count, Enrollment.count]).to eq(original_counts)
      expect(response.body).to include(I18n.t("public.inquiries.success.title", locale: :ar))
      expect(PublicInquiry.last).to have_attributes(inquiry_type: "trial", preferred_locale: "ar",
                                                    name: "آمنة حسن", phone: "+201012345678")
      expect(response.body).not_to include(PublicInquiry.last.public_id, "amina@example.test", "+201012345678")
    end

    it "renders safe validation errors without creating a lead" do
      expect do
        post public_trial_path(locale: :en), params: { public_inquiry: { name: "<script>alert(1)</script>" } }
      end.not_to change(PublicInquiry, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).not_to include("<script>alert(1)</script>")
      expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "silently accepts a filled honeypot without persisting it" do
      expect do
        post public_trial_path(locale: :en), params: {
          public_inquiry: { name: "Bot", phone: "+201001234567", website: "https://spam.example" }
        }
      end.not_to change(PublicInquiry, :count)

      expect(response).to have_http_status(:accepted)
      expect(response.body).to include(I18n.t("public.inquiries.success.title", locale: :en))
    end
  end

  describe "contact requests" do
    it "renders Arabic and English forms" do
      get public_contact_path(locale: :ar)
      expect(response.body).to include('<html lang="ar" dir="rtl">', I18n.t("public.contact.title", locale: :ar))

      get public_contact_path(locale: :en)
      expect(response.body).to include('<html lang="en" dir="ltr">', I18n.t("public.contact.title", locale: :en))
    end

    it "creates a contact lead with email and a required message" do
      post public_contact_path(locale: :en), params: {
        public_inquiry: { name: "Amina", email: "amina@example.test", subject: "Question",
                          message: "Please tell me more." }
      }

      expect(response).to have_http_status(:created)
      expect(PublicInquiry.last).to have_attributes(inquiry_type: "contact", preferred_locale: "en",
                                                    message: "Please tell me more.")
    end

    it "validates contact details and message" do
      post public_contact_path(locale: :en), params: {
        public_inquiry: { name: "Amina", email: "invalid", message: "" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PublicInquiry).not_to exist
    end
  end

  it "preserves the disabled public website behavior" do
    academy_setting.public_website_setting.update!(enabled: false)

    get public_trial_path(locale: :en)
    expect(response).to have_http_status(:service_unavailable)

    post public_contact_path(locale: :en), params: {
      public_inquiry: { name: "Amina", email: "amina@example.test", message: "Hello" }
    }
    expect(response).to have_http_status(:service_unavailable)
    expect(PublicInquiry).not_to exist
  end
end
