module ManualCommunications
  class Prepare
    def initialize(actor:, entry:, recipient:, **options)
      @actor = actor
      @entry = entry
      @recipient = recipient
      @builder = MessageBuilder.new(entry:, recipient:, **options)
      @channel = options[:channel]
      @template_type = options[:template_type]
    end

    def call
      return failed_log(:forbidden) unless authorized?

      result = @builder.call
      CommunicationLog.transaction { result.valid? ? create_prepared!(result) : create_failed!(result.error) }
    end

    private

    def create_prepared!(result)
      log = base_log(result.masked_address).tap do |record|
        record.assign_attributes(recipient_locale: result.locale, message_snapshot: result.body,
                                 subject_snapshot: result.subject, external_url: result.external_url,
                                 status: "prepared")
        record.save!
      end
      event!(log, "prepared", "prepared")
      log
    end

    def create_failed!(error)
      log = base_log("unavailable").tap do |record|
        record.assign_attributes(recipient_locale: resolved_locale,
                                 message_snapshot: I18n.t("manual_communications.failed"),
                                 status: "failed", failure_reason: error.to_s)
        record.save!
      end
      event!(log, "failed", "failed")
      log
    end

    def failed_log(error)
      log = base_log("unavailable")
      log.errors.add(:base, error)
      log
    end

    def base_log(masked)
      CommunicationLog.new(public_id: nil, scheduled_lesson: @entry.scheduled_lesson,
                           lesson_report: @entry.lesson_report, lesson_student_report: @entry,
                           student_profile: @entry.student_profile, guardian: guardian,
                           recipient_user: recipient_user, actor: @actor, channel: @channel,
                           template_type: @template_type, recipient_address_masked: masked,
                           prepared_at: Time.current)
    end

    def event!(log, type, status)
      CommunicationLogEvent.create!(communication_log: log, actor: @actor, event_type: type,
                                    after_data: { "status" => status })
    end

    def authorized?
      return false unless @actor.active?
      return true if @actor.admin?

      @actor.teacher? && @entry.lesson_report.teacher_profile.user_id == @actor.id
    end

    def guardian
      @recipient if @recipient.is_a?(Guardian)
    end

    def recipient_user
      @recipient unless @recipient.is_a?(Guardian)
    end

    def resolved_locale
      return I18n.default_locale.to_s unless @recipient

      (@recipient.respond_to?(:preferred_language) ? @recipient.preferred_language : @recipient.preferred_locale).to_s
    end
  end
end
