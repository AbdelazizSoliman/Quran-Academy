module Notifications
  class Dispatch
    def initialize(actor:, recipient:, source:, type:, channel:, primary_guardian: false,
                   idempotency_key: nil, scheduled_at: nil, queued_at: nil,
                   invitation_token: nil, persist_recipient_failure: false)
      @actor = actor
      @recipient = recipient
      @source = source
      @type = type.to_s
      @channel = channel.to_s
      @primary_guardian = primary_guardian
      @idempotency_key = idempotency_key
      @scheduled_at = scheduled_at
      @queued_at = queued_at
      @invitation_token = invitation_token
      @persist_recipient_failure = persist_recipient_failure
    end

    def call
      notification = build_notification
      return invalid(notification, :forbidden) unless authorized?
      return invalid(notification, :invalid_source) unless source_valid?
      existing = Notification.find_by(idempotency_key: @idempotency_key) if @idempotency_key.present?
      return existing if existing
      return recipient_failure(notification, :channel_disabled) unless channel_enabled?
      return invalid(notification, :notification_type_disabled) unless notification_type_enabled?

      resolved = RecipientResolver.new(user: @recipient, channel: @channel,
                                       primary_guardian: @primary_guardian).call
      return recipient_failure(notification, resolved.error) unless resolved.valid?

      token = invitation_token
      message = MessageBuilder.new(type: @type, source: @source, recipient: @recipient,
                                   locale: resolved.locale, invitation_token: token).call
      notification.assign_attributes(recipient_guardian: resolved.guardian, provider: provider_name,
                                     recipient_address_masked: resolved.masked_address,
                                     recipient_locale: resolved.locale, subject: message.subject,
                                     message_snapshot: stored_message(message.body),
                                     delivery_payload_ciphertext: invitation_payload(message.body))
      Notification.transaction do
        notification.save!
        event!(notification, "created", after_data: { "status" => "pending" })
      end
      ActiveRecord.after_all_transactions_commit do
        NotificationAttemptJob.perform_later(notification:, actor: @actor)
      end
      notification
    rescue ActiveRecord::RecordInvalid
      notification
    rescue ActiveRecord::RecordNotUnique
      Notification.find_by!(idempotency_key: @idempotency_key)
    end

    private

    def build_notification
      Notification.new(recipient_user: @recipient, actor: @actor, source: @source, channel: @channel,
                       notification_type: @type, recipient_locale: locale,
                       recipient_address_masked: "unavailable", message_snapshot: "unavailable",
                       idempotency_key: @idempotency_key, scheduled_at: @scheduled_at, queued_at: @queued_at)
    end

    def authorized?
      return false unless @actor.active?
      return true if @actor.admin?
      return false unless @actor.teacher?

      teacher_id = @actor.teacher_profile&.id
      case @source
      when ScheduledLesson then @source.teacher_profile_id == teacher_id
      when LessonReport then @source.teacher_profile_id == teacher_id
      else false
      end
    end

    def source_valid?
      Notification::TYPES.include?(@type) && Notification::CHANNELS.include?(@channel) &&
        { "account_invitation" => AccountInvitation, "lesson_pre_reminder" => ScheduledLesson,
          "lesson_late_reminder" => ScheduledLesson, "lesson_reminder" => ScheduledLesson,
          "late_reminder" => ScheduledLesson, "lesson_cancelled" => ScheduledLesson,
          "lesson_rescheduled" => ScheduledLesson, "lesson_report" => LessonReport,
          "certificate" => Certificate }[@type] === @source &&
        source_deliverable? && lesson_join_url_valid? && recipient_belongs_to_source?
    end

    def source_deliverable?
      case @source
      when AccountInvitation then @source.usable?
      when ScheduledLesson
        @type == "lesson_cancelled" ? @source.cancelled? : @source.status.in?(%w[scheduled in_progress])
      when LessonReport then @source.status.in?(%w[reviewed locked])
      when Certificate then true
      else false
      end
    end

    def recipient_belongs_to_source?
      case @source
      when AccountInvitation then @source.user_id == @recipient.id
      when ScheduledLesson
        @source.teacher_profile.user_id == @recipient.id ||
          @source.enrollments.joins(student_profile: :user).exists?(users: { id: @recipient.id })
      when LessonReport then @source.lesson_student_reports.joins(student_profile: :user).exists?(users: { id: @recipient.id })
      when Certificate then @source.student_profile.user_id == @recipient.id
      else false
      end
    end

    def notification_type_enabled?
      setting = AcademySetting.current
      { "account_invitation" => setting.invitation_notifications_enabled?,
        "lesson_pre_reminder" => setting.lesson_reminders_enabled?,
        "lesson_late_reminder" => setting.lesson_reminders_enabled?,
        "lesson_reminder" => setting.lesson_reminders_enabled?,
        "late_reminder" => setting.lesson_reminders_enabled?,
        "lesson_cancelled" => setting.lesson_reminders_enabled?,
        "lesson_rescheduled" => setting.lesson_reminders_enabled?,
        "lesson_report" => setting.lesson_report_notifications_enabled? && setting.lesson_report_whatsapp_enabled?,
        "certificate" => setting.certificate_notifications_enabled? }.fetch(@type, false)
    end

    def channel_enabled?
      setting = AcademySetting.current
      return false unless channel_allowed_for_type?(setting)

      @channel == "email" ? setting.email_notifications_enabled? : setting.whatsapp_notifications_enabled?
    end

    def channel_allowed_for_type?(setting)
      return invitation_channel_allowed?(setting) if @type == "account_invitation"
      return @channel == "whatsapp" if @type.in?(%w[lesson_pre_reminder lesson_late_reminder lesson_reminder
                                                     late_reminder lesson_cancelled
                                                     lesson_rescheduled lesson_report])
      return @channel == "email" || (@channel == "whatsapp" && setting.certificate_whatsapp_enabled?) if @type == "certificate"

      false
    end

    def invitation_channel_allowed?(setting)
      mode = setting.invitation_delivery_mode
      return mode.in?(%w[email_only email_and_whatsapp]) if @channel == "email"

      mode.in?(%w[whatsapp_only email_and_whatsapp])
    end

    def lesson_join_url_valid?
      return true unless @type.in?(%w[lesson_pre_reminder lesson_late_reminder])

      return false unless @source.safe_online_meeting_join_url

      join_url = LessonJoinUrlBuilder.call(lesson: @source, recipient: @recipient)
      LessonJoinUrlSuffix.call(join_url:).present?
    end

    def invitation_token
      return unless @type == "account_invitation"

      @invitation_token.presence || rotate_invitation_token
    end

    def rotate_invitation_token
      raw = AccountInvitations::Token.generate
      @source.with_lock do
        @source.update!(token_digest: AccountInvitations::Token.digest(raw), expires_at: invitation_expiry,
                        status: "sent", resent_count: @source.resent_count + 1, last_sent_at: Time.current)
        @source.events.create!(actor: @actor, event_type: "resent", after_data: { "status" => "sent" })
      end
      raw
    end

    def invitation_expiry = AcademySetting.current.invitation_expires_after_hours.hours.from_now
    def stored_message(body) = @type == "account_invitation" ? I18n.t("notifications.secure_link_omitted") : body
    def invitation_payload(body)
      return unless @type == "account_invitation"

      Notifications::SecurePayload.encrypt(body)
    end
    def locale = @recipient.preferred_locale.to_s.presence_in(%w[ar en]) || AcademySetting.current.default_locale
    def provider_name = @channel == "whatsapp" ? "meta_whatsapp" : "resend"

    def event!(notification, event_type, after_data: {})
      notification.events.create!(actor: @actor, event_type:, after_data:)
    end

    def invalid(notification, key)
      notification.errors.add(:base, key)
      notification
    end

    def recipient_failure(notification, key)
      return invalid(notification, key) unless @persist_recipient_failure

      message = MessageBuilder.new(type: @type, source: @source, recipient: @recipient,
                                   locale:, invitation_token:).call
      notification.assign_attributes(provider: provider_name, subject: message.subject,
                                     message_snapshot: stored_message(message.body),
                                     delivery_payload_ciphertext: invitation_payload(message.body),
                                     failure_code: key.to_s, failure_reason: I18n.t("errors.messages.#{key}"),
                                     failed_at: Time.current)
      Notification.transaction do
        notification.save!
        event!(notification, "created", after_data: { "status" => "pending" })
        notification.update!(status: "failed")
        event!(notification, "failed", after_data: { "status" => "failed", "failure_code" => key.to_s })
      end
      notification
    end
  end
end
