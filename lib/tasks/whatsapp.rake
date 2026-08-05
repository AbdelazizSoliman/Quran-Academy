namespace :whatsapp do
  desc "Explicitly send one account-setup template to an existing invitation"
  task smoke_account_setup: :environment do
    enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("WHATSAPP_ENABLED", nil))
    abort "Refusing: set WHATSAPP_ENABLED=true" unless enabled
    abort "Refusing: set CONFIRM_SEND_ACCOUNT_SETUP=yes" unless ENV["CONFIRM_SEND_ACCOUNT_SETUP"] == "yes"
    abort "Refusing: set INVITATION_ID explicitly" if ENV["INVITATION_ID"].blank?

    invitation = AccountInvitation.find(ENV.fetch("INVITATION_ID"))
    abort "Refusing: invitation is not currently usable" unless invitation.usable?
    abort "Refusing: RAW_INVITATION_TOKEN is required" if ENV["RAW_INVITATION_TOKEN"].blank?
    unless ActiveSupport::SecurityUtils.secure_compare(
      invitation.token_digest, AccountInvitations::Token.digest(ENV.fetch("RAW_INVITATION_TOKEN"))
    )
      abort "Refusing: token does not match the selected invitation"
    end

    actor_id = ENV["ACTOR_ID"].presence || invitation.created_by_id
    actor = User.find(actor_id)
    result = Notifications::AccountSetupDelivery.new(
      invitation:, actor:, token: ENV.fetch("RAW_INVITATION_TOKEN")
    ).call
    abort "Account-setup delivery was safely skipped; verify configuration and recipient" unless result
    unless result.sent? || result.delivered?
      abort "Account-setup delivery failed safely; inspect sanitized notification audit"
    end

    puts "Account-setup delivery processed for #{invitation.public_id}; status=#{result.status}"
  end
end
