require "uri"

module ManualCommunications
  MessageResult = Data.define(:valid?, :channel, :locale, :recipient_address, :masked_address, :subject, :body,
                              :external_url, :error)

  class MessageBuilder
    def initialize(channel:, template_type:, entry:, recipient:, locale: nil)
      @channel = channel.to_s
      @template_type = template_type.to_s
      @entry = entry
      @recipient = recipient
      @locale = resolve_locale(locale)
    end

    def call
      return failure(:invalid_channel) unless @channel.in?(CommunicationLog::CHANNELS)
      return failure(:invalid_template) unless @template_type.in?(CommunicationLog::TEMPLATE_TYPES)

      address = recipient_address
      return failure(:missing_recipient) if address.blank?

      @channel == "whatsapp" ? whatsapp_result(address) : email_result(address)
    end

    private

    def whatsapp_result(address)
      phone = PhoneNormalizer.call(address)
      return failure(phone.error) unless phone.valid?

      build_result(phone.digits, mask_phone(phone.digits), "https://wa.me/#{phone.digits}?text=#{encoded(body)}")
    end

    def email_result(address)
      return failure(:invalid_email) unless address.match?(URI::MailTo::EMAIL_REGEXP)

      url = "mailto:#{address}?#{URI.encode_www_form(subject: subject, body: body)}"
      build_result(address, mask_email(address), url)
    end

    def build_result(address, masked, url)
      MessageResult.new(true, @channel, @locale, address, masked, subject, body, url, nil)
    end

    def failure(error)
      MessageResult.new(false, @channel, @locale, nil, "unavailable", nil, nil, nil, error)
    end

    def body
      I18n.with_locale(@locale) do
        I18n.t("manual_communications.messages.#{@template_type}", **template_values)
      end
    end

    def template_values
      { academy: academy_name, student: @entry.student_profile.display_name, lesson: lesson_title,
        date: I18n.l(@entry.scheduled_lesson.starts_at.to_date, format: :long), teacher: teacher_name,
        summary: @entry.lesson_report.lesson_summary.to_s, homework: homework,
        target: @entry.next_lesson_target.to_s, attendance: attendance_label }
    end

    def subject
      I18n.with_locale(@locale) do
        I18n.t("manual_communications.subject", academy: academy_name, student: @entry.student_profile.display_name)
      end
    end

    def recipient_address
      if @recipient.is_a?(Guardian)
        @channel == "whatsapp" ? @recipient.whatsapp_number : @recipient.email
      else
        profile = @entry.student_profile
        @channel == "whatsapp" ? profile.whatsapp_number : profile.user.email
      end
    end

    def resolve_locale(explicit)
      candidate = explicit || recipient_locale || AcademySetting.current.default_locale
      candidate.to_s.presence_in(%w[ar en]) || I18n.default_locale.to_s
    end

    def recipient_locale
      @recipient.is_a?(Guardian) ? @recipient.preferred_language : @entry.student_profile.user.preferred_locale
    end

    def lesson_title
      @locale == "ar" ? @entry.scheduled_lesson.title_ar : @entry.scheduled_lesson.title_en
    end

    def teacher_name = @entry.lesson_report.teacher_profile.display_name
    def academy_name = AcademySetting.current.academy_name
    def homework = @entry.homework.presence || @entry.lesson_report.general_homework.to_s

    def attendance_label
      attendance = @entry.scheduled_lesson_enrollment.lesson_attendance
      I18n.t("attendance.statuses.#{attendance&.status || 'pending'}", locale: @locale)
    end

    def encoded(value) = URI.encode_www_form_component(value)
    def mask_phone(value) = "#{'*' * [value.length - 4, 0].max}#{value.last(4)}"

    def mask_email(value)
      local, domain = value.split("@", 2)
      "#{local.first}***@#{domain}"
    end
  end
end
