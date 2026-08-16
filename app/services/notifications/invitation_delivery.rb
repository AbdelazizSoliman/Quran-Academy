module Notifications
  # Authoritative entry point for delivering an account invitation. Determines which channels
  # to attempt from the recipient's own stored preference (Notifications::InvitationChannels),
  # then attempts each requested channel independently — a failure or skip on one channel never
  # prevents the other from being attempted. Provider calls run synchronously after the current
  # transaction commits. The authoritative, evolving truth for
  # both channels always lives on the per-channel Notification/NotificationAttempt records.
  class InvitationDelivery
    Result = Data.define(:requested, :succeeded, :failed, :skipped)

    def initialize(invitation:, token:, actor:)
      @invitation = invitation
      @token = token
      @actor = actor
    end

    def call
      Rails.logger.info("InvitationDelivery started invitation_id=#{@invitation.public_id}")
      channels = InvitationChannels.call(user: @invitation.user)
      succeeded = []
      failed = []
      skipped = []

      attempt_email(channels, succeeded, failed)
      attempt_whatsapp(channels, succeeded, skipped)

      Result.new(requested: channels, succeeded:, failed:, skipped:)
    end

    private

    def attempt_email(channels, succeeded, failed)
      return unless channels.include?("email")

      deliver_email ? succeeded << "email" : failed << "email"
    end

    def attempt_whatsapp(channels, succeeded, skipped)
      return unless channels.include?("whatsapp")

      reason = whatsapp_skip_reason
      if reason
        Rails.logger.info(
          "InvitationDelivery whatsapp dispatch skipped reason=#{reason} invitation_id=#{@invitation.public_id}"
        )
        skipped << "whatsapp"
      else
        deliver_whatsapp_after_commit
        succeeded << "whatsapp"
      end
    end

    def deliver_email
      setting = AcademySetting.current
      return false unless setting.email_notifications_enabled? && setting.invitation_notifications_enabled?

      Rails.logger.info("InvitationDelivery email dispatch started invitation_id=#{@invitation.public_id}")
      ActiveRecord.after_all_transactions_commit { deliver_email_now }
      Rails.logger.info("InvitationDelivery email dispatch finished success=true")
      true
    rescue StandardError => e
      Rails.logger.error("Invitation email delivery failed (#{e.class})")
      Rails.logger.info("InvitationDelivery email dispatch finished success=false")
      false
    end

    def deliver_email_now
      delivered = InvitationEmailDelivery.new(invitation: @invitation, token: @token, actor: @actor).call
      AccountInvitations::MarkSent.call(invitation: @invitation, actor: @actor) if delivered
    rescue StandardError => e
      Rails.logger.error("Synchronous invitation email delivery failed (#{e.class})")
    end

    # Cheap, local, side-effect-free eligibility check so a skip can be decided and logged
    # synchronously. AccountSetupDelivery independently re-validates everything (defense in depth)
    # after commit, since state could change between the eligibility check and delivery.
    def whatsapp_skip_reason
      return :disabled unless WhatsappConfiguration.enabled?
      return :not_configured unless WhatsappConfiguration.configured?
      return :invalid_token unless current_token?

      recipient = RecipientResolver.new(user: @invitation.user, channel: "whatsapp").call
      return :invalid_number unless recipient.valid?
      return :url_prefix_mismatch unless url_suffix_available?(recipient.locale)

      nil
    rescue StandardError => e
      Rails.logger.error("WhatsApp invitation eligibility check failed (#{e.class})")
      :check_failed
    end

    def current_token?
      @invitation.usable? && ActiveSupport::SecurityUtils.secure_compare(
        @invitation.token_digest, AccountInvitations::Token.digest(@token)
      )
    end

    # Only checks whether a suffix can be derived at all; the suffix itself is discarded
    # immediately and never logged, stored, or returned (it is derived from the raw token).
    def url_suffix_available?(locale)
      url = AccountInvitations::UrlBuilder.call(token: @token, locale:)
      AccountSetupUrlSuffix.call(invitation_url: url).present?
    end

    def deliver_whatsapp_after_commit
      Rails.logger.info("InvitationDelivery whatsapp dispatch started invitation_id=#{@invitation.public_id}")
      ActiveRecord.after_all_transactions_commit { deliver_whatsapp_now }
    rescue StandardError => e
      Rails.logger.error("WhatsApp invitation preparation failed (#{e.class})")
    end

    def deliver_whatsapp_now
      AccountSetupDelivery.new(invitation: @invitation, actor: @actor, token: @token).call
      Rails.logger.info(
        "InvitationDelivery whatsapp dispatch finished success=true invitation_id=#{@invitation.public_id}"
      )
    rescue StandardError => e
      Rails.logger.error("Synchronous WhatsApp invitation delivery failed (#{e.class})")
      Rails.logger.info(
        "InvitationDelivery whatsapp dispatch finished success=false invitation_id=#{@invitation.public_id}"
      )
    end
  end
end
