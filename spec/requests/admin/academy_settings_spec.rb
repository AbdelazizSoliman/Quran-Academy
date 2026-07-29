require "rails_helper"

RSpec.describe "Academy settings administration" do
  let(:admin) { create(:user, :admin) }
  let!(:setting) { AcademySetting.current }

  before { AcademySettingEvent.delete_all }

  it "redirects unauthenticated access to sign in" do
    get admin_settings_path
    expect(response).to redirect_to(new_user_session_path)
  end

  %i[staff teacher student].each do |role|
    it "forbids an active #{role}" do
      sign_in create(:user, role)
      get admin_settings_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  %i[pending suspended disabled].each do |status|
    it "does not authenticate a #{status} administrator" do
      sign_in create(:user, :admin, status)
      get admin_settings_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "renders a localized Arabic summary without raw arrays or JSON" do
    sign_in admin
    get admin_settings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('dir="rtl"', "إعدادات الأكاديمية", "السبت", "العربية")
    expect(response.body).to include(I18n.t("admin.settings.not_configured", locale: :ar))
    expect(response.body).not_to include(setting.working_days.inspect, "translation missing")
  end

  it "renders English LTR, boolean badges, last updater, and audit history" do
    admin.update!(preferred_locale: "en")
    setting.update!(updated_by: admin)
    create(:academy_setting_event, academy_setting: setting, actor: admin)
    sign_in admin
    get admin_settings_path

    expect(response.body).to include('dir="ltr"', "Academy settings", "Enabled", admin.full_name)
    expect(response.body).to include("updated: Academy name")
  end

  it "updates every settings category, normalizes arrays, and handles unchecked booleans" do
    sign_in admin
    patch admin_settings_path, params: {
      academy_setting: valid_update.merge(
        supported_locales: ["", "en", "ar", "en"],
        teaching_languages: ["", "fr", "ar", "fr"],
        working_days: ["", "monday", "sunday", "monday"],
        email_notifications_enabled: "0", allow_student_self_cancellation: "0"
      )
    }

    expect(response).to redirect_to(admin_settings_path)
    setting.reload
    expect(setting.supported_locales).to eq(%w[ar en])
    expect(setting.teaching_languages).to eq(%w[ar fr])
    expect(setting.working_days).to eq(%w[sunday monday])
    expect(setting.email_notifications_enabled).to be(false)
    expect(setting.allow_student_self_cancellation).to be(false)
    expect(setting.updated_by).to eq(admin)
    expect(setting.events.count).to eq(1)
  end

  it "rejects invalid changes, preserves submitted values, and creates no audit" do
    sign_in admin
    patch admin_settings_path, params: {
      academy_setting: valid_update.merge(academy_name: "", website_url: "bad",
                                          day_starts_at: "22:00", day_ends_at: "08:00")
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("value=\"bad\"")
    expect(setting.events.count).to eq(0)
    expect(setting.reload.academy_name).to eq("Quran Academy")
  end

  it "does not mass assign singleton, actor, audit metadata, IDs, or timestamps" do
    other = create(:user, :admin)
    sign_in admin
    patch admin_settings_path, params: {
      academy_setting: valid_update.merge(singleton_key: "other", updated_by_id: other.id,
                                          metadata: { password: "unsafe" }, created_at: 10.years.ago)
    }

    setting.reload
    expect(setting.singleton_key).to eq("current")
    expect(setting.updated_by).to eq(admin)
    expect(setting.events.last.metadata.to_s).not_to include("unsafe", "password")
  end

  it "exposes only singular read/edit/update routes" do
    get "/admin/settings/new"
    expect(response).to have_http_status(:not_found)
    post "/admin/settings"
    expect(response).to have_http_status(:not_found)
    delete admin_settings_path
    expect(response).to have_http_status(:not_found)
  end

  private

  def valid_update
    {
      academy_name: "Al Noor Academy", legal_name: "Al Noor Learning", contact_email: "contact@example.test",
      website_url: "https://example.test", country_code: "EG", default_locale: "ar",
      default_time_zone: "Cairo", day_starts_at: "08:00", day_ends_at: "22:00",
      default_lesson_duration_minutes: 30, minimum_lesson_duration_minutes: 15,
      maximum_lesson_duration_minutes: 120, lesson_duration_step_minutes: 15,
      minimum_booking_notice_hours: 2, maximum_booking_window_days: 90, reschedule_notice_hours: 12,
      student_cancellation_notice_hours: 12, teacher_cancellation_notice_hours: 12,
      late_cancellation_window_hours: 2, student_late_after_minutes: 5, teacher_late_after_minutes: 5,
      absence_after_minutes: 15, lesson_reminder_hours_before: 24,
      second_lesson_reminder_minutes_before: 60, default_teacher_compensation_type: "per_lesson",
      default_teacher_rate: "250.00", payroll_currency: "EGP", payroll_period: "monthly",
      billing_currency: "EGP", default_lesson_price: "300.00", billing_cycle: "monthly",
      supported_locales: %w[ar en], teaching_languages: %w[ar en], working_days: %w[sunday monday]
    }
  end
end
