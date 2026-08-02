module Notifications
  class Dispatch
    def initialize(actor:, recipient:, source:, type:, channel:, primary_guardian: false)
      @actor = actor
      @recipient = recipient
      @source = source
      @type = type.to_s
      @channel = channel.to_s
      @primary_guardian = primary_guardian
    end

    def call
      notification = build_notification
      return invalid(notification, :forbidden) unless authorized?
      return invalid(notification, :channel_disabled) unless channel_enabled?
      return invalid(notification, :notification_type_disabled) unless notification_type_enabled?
      return invalid(notification, :invalid_source) unless source_valid?

      resolved = RecipientResolver.new(user: @recipient, channel: @channel,
                                       primary_guardian: @primary_guardian).call
      return invalid(notification, resolved.error) unless resolved.valid?

      token = rotate_invitation_token if @type == "account_invitation"
      message = MessageBuilder.new(type: @type, source: @source, recipient: @recipient,
                                   locale: resolved.locale, invitation_token: token).call
      notification.assign_attributes(recipient_guardian: resolved.guardian, provider: provider_name,
                                     recipient_address_masked: resolved.masked_address,
                                     recipient_locale: resolved.locale, subject: message.subject,
                                     message_snapshot: stored_message(message.body))
      Notification.transaction do
        notification.save!
        event!(notification, "created", after_data: { "status" => "pending" })
      end
      Attempt.new(notification:, actor: @actor, recipient_address: resolved.provider_address,
                  delivery_body: message.body).call
    rescue ActiveRecord::RecordInvalid
      notification
    end

    private

    def build_notification
      Notification.new(recipient_user: @recipient, actor: @actor, source: @source, channel: @channel,
                       notification_type: @type, recipient_locale: locale,
                       recipient_address_masked: "unavailable", message_snapshot: "unavailable")
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
        { "account_invitation" => AccountInvitation, "lesson_reminder" => ScheduledLesson,
          "lesson_report" => LessonReport, "certificate" => Certificate }[@type] === @source &&
        source_deliverable? && recipient_belongs_to_source?
    end

    def source_deliverable?
      case @source
      when AccountInvitation then @source.usable?
      when ScheduledLesson then @source.status.in?(%w[scheduled in_progress])
      when LessonReport then @source.status.in?(%w[reviewed locked])
      when Certificate then true
      else false
      end
    end

    def recipient_belongs_to_source?
      case @source
      when AccountInvitation then @source.user_id == @recipient.id
      when ScheduledLesson then @source.enrollments.joins(student_profile: :user).exists?(users: { id: @recipient.id })
      when LessonReport then @source.lesson_student_reports.joins(student_profile: :user).exists?(users: { id: @recipient.id })
      when Certificate then @source.student_profile.user_id == @recipient.id
      else false
      end
    end

    def channel_enabled?
      setting = AcademySetting.current
      @channel == "email" ? setting.email_notifications_enabled? : setting.whatsapp_notifications_enabled?
    end

    def notification_type_enabled?
      setting = AcademySetting.current
      { "account_invitation" => setting.invitation_notifications_enabled?,
        "lesson_reminder" => setting.lesson_reminders_enabled?,
        "lesson_report" => setting.lesson_report_notifications_enabled?,
        "certificate" => setting.certificate_notifications_enabled? }.fetch(@type, false)
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
    def locale = @recipient.preferred_locale.to_s.presence_in(%w[ar en]) || AcademySetting.current.default_locale
    def provider_name = @channel == "whatsapp" ? "meta_whatsapp" : "resend"

    def event!(notification, event_type, after_data: {})
      notification.events.create!(actor: @actor, event_type:, after_data:)
    end

    def invalid(notification, key)
      notification.errors.add(:base, key)
      notification
    end
  end
end
