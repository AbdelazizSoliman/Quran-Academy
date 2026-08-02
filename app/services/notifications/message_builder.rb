module Notifications
  Message = Data.define(:subject, :body)

  class MessageBuilder
    def initialize(type:, source:, recipient:, locale:, invitation_token: nil)
      @type = type
      @source = source
      @recipient = recipient
      @locale = locale
      @invitation_token = invitation_token
    end

    def call
      I18n.with_locale(@locale) do
        Message.new(I18n.t("notifications.messages.#{@type}.subject", **values),
                    I18n.t("notifications.messages.#{@type}.body", **values))
      end
    end

    private

    def values
      { academy: AcademySetting.current.academy_name, recipient: @recipient.full_name,
        date: source_date, title: source_title, url: source_url }
    end

    def source_date
      value = @source.respond_to?(:starts_at) ? @source.starts_at : @source.try(:issued_on)
      value ? I18n.l(value.to_date, format: :long) : ""
    end

    def source_title
      if @source.is_a?(ScheduledLesson)
        return @locale == "ar" ? @source.title_ar : @source.title_en
      end
      if @source.is_a?(LessonReport)
        lesson = @source.scheduled_lesson
        return @locale == "ar" ? lesson.title_ar : lesson.title_en
      end

      @source.try(:public_id).to_s
    end

    def source_url
      helpers = Rails.application.routes.url_helpers
      options = Rails.application.config.action_mailer.default_url_options
      case @source
      when AccountInvitation
        helpers.edit_account_invitation_url(token: @invitation_token, locale: @locale, **options)
      when LessonReport
        entry = @source.lesson_student_reports.find_by(student_profile: @recipient.student_profile)
        entry ? helpers.student_report_url(entry, **options) : ""
      when Certificate
        helpers.student_certificate_url(@source, **options)
      else
        ""
      end
    end
  end
end
