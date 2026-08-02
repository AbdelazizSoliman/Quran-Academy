module Admin
  class AcademySettingsController < BaseController
    before_action :set_setting

    def show
      @events = @setting.events.includes(:actor).order(created_at: :desc).limit(20)
    end

    def edit; end

    def update
      @setting = AcademySettings::Update.new(
        setting: @setting, actor: current_user, attributes: setting_params
      ).call
      if @setting.errors.empty?
        redirect_to admin_settings_path, notice: t("admin.settings.messages.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_setting
      @setting = AcademySetting.current
    end

    def setting_params
      params.expect(academy_setting: [
                      *scalar_fields,
                      { supported_locales: [], teaching_languages: [], working_days: [],
                        assessment_grade_boundaries: {} }
                    ])
    end

    def scalar_fields
      %i[
        academy_name legal_name short_name description contact_email contact_phone whatsapp_number
        website_url address_line_1 address_line_2 city state_or_region postal_code country_code
        default_locale default_time_zone day_starts_at day_ends_at default_lesson_duration_minutes
        minimum_lesson_duration_minutes maximum_lesson_duration_minutes lesson_duration_step_minutes
        minimum_booking_notice_hours maximum_booking_window_days reschedule_notice_hours
        student_cancellation_notice_hours teacher_cancellation_notice_hours late_cancellation_window_hours
        allow_student_self_cancellation allow_teacher_self_cancellation student_late_after_minutes
        teacher_late_after_minutes absence_after_minutes allow_manual_attendance_adjustment
        teacher_check_in_opens_minutes_before teacher_check_in_closes_minutes_after left_early_threshold_minutes
        email_notifications_enabled whatsapp_notifications_enabled sms_notifications_enabled
        invitation_notifications_enabled lesson_reminders_enabled lesson_report_notifications_enabled
        certificate_notifications_enabled certificate_whatsapp_enabled lesson_report_whatsapp_enabled
        attendance_notifications_enabled payment_notifications_enabled lesson_reminder_minutes_before
        first_late_reminder_minutes second_late_reminder_minutes lesson_reminder_hours_before
        second_lesson_reminder_minutes_before default_teacher_compensation_type
        default_teacher_rate payroll_currency payroll_period billing_currency default_lesson_price billing_cycle
        invitation_expires_after_hours
      ]
    end
  end
end
