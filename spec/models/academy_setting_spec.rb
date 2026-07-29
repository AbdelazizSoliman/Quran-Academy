require "rails_helper"

RSpec.describe AcademySetting do
  before do
    AcademySettingEvent.delete_all
    described_class.delete_all
  end

  it "provides one valid singleton with operational defaults" do
    first = described_class.current
    second = described_class.current

    expect(first).to eq(second)
    expect(first).to be_valid
    expect(first.attributes).to include(
      "academy_name" => "Quran Academy", "default_locale" => "ar",
      "default_time_zone" => "Cairo", "country_code" => "EG"
    )
  end

  it "prevents a duplicate singleton" do
    described_class.current
    duplicate = build(:academy_setting)

    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "normalizes arrays, email, country, and currencies" do
    setting = build(:academy_setting, supported_locales: ["", "en", "ar", "en"],
                                      working_days: %w[monday sunday monday],
                                      contact_email: " ADMIN@EXAMPLE.TEST ",
                                      country_code: "eg", payroll_currency: "egp")
    setting.validate

    expect(setting.supported_locales).to eq(%w[ar en])
    expect(setting.working_days).to eq(%w[sunday monday])
    expect(setting.contact_email).to eq("admin@example.test")
    expect(setting.country_code).to eq("EG")
    expect(setting.payroll_currency).to eq("EGP")
  end

  it "validates identity, contact, locale, zone, and catalogs" do
    setting = build(:academy_setting, academy_name: "", contact_email: "bad", website_url: "ftp://bad",
                                      country_code: "EGY", default_locale: "fr", supported_locales: ["ar"],
                                      default_time_zone: "Invalid", teaching_languages: ["xx"],
                                      working_days: ["holiday"])

    expect(setting).not_to be_valid
    expect(setting.errors).to include(:academy_name, :contact_email, :website_url, :country_code,
                                      :default_locale, :default_time_zone, :teaching_languages, :working_days)
  end

  it "requires nonempty collections and the default locale to be supported" do
    setting = build(:academy_setting, default_locale: "en", supported_locales: [], teaching_languages: [],
                                      working_days: [])

    expect(setting).not_to be_valid
    expect(setting.errors).to include(:supported_locales, :teaching_languages, :working_days, :default_locale)
  end

  it "validates operating hours and lesson duration relationships" do
    setting = build(:academy_setting, day_starts_at: "22:00", day_ends_at: "08:00",
                                      minimum_lesson_duration_minutes: 60,
                                      default_lesson_duration_minutes: 30,
                                      maximum_lesson_duration_minutes: 20,
                                      lesson_duration_step_minutes: 7)

    expect(setting).not_to be_valid
    expect(setting.errors).to include(:day_ends_at, :default_lesson_duration_minutes,
                                      :lesson_duration_step_minutes)
  end

  it "validates scheduling, cancellation, attendance, money, and codes" do
    setting = build(:academy_setting, maximum_booking_window_days: 900,
                                      late_cancellation_window_hours: 13,
                                      student_cancellation_notice_hours: 12,
                                      teacher_cancellation_notice_hours: 12,
                                      student_late_after_minutes: 20, absence_after_minutes: 15,
                                      default_teacher_rate: -1, default_lesson_price: -1,
                                      payroll_currency: "LE", billing_currency: "123")

    expect(setting).not_to be_valid
    expect(setting.errors).to include(:maximum_booking_window_days, :late_cancellation_window_hours,
                                      :absence_after_minutes, :default_teacher_rate,
                                      :default_lesson_price, :payroll_currency, :billing_currency)
  end
end
