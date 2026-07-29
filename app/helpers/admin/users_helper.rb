module Admin
  module UsersHelper
    STATUS_VARIANTS = {
      "pending" => :warning, "active" => :success, "suspended" => :danger, "disabled" => :neutral
    }.freeze

    def user_status_badge(user)
      render "shared/components/badge",
             label: t("statuses.#{user.status}"),
             variant: STATUS_VARIANTS.fetch(user.status)
    end

    def user_role_badge(user)
      render "shared/components/badge", label: t("roles.#{user.role}"), variant: :information
    end

    def admin_user_transition_actions(user)
      {
        approve: user.pending?,
        suspend: user.active? && user != current_user,
        activate: user.suspended?,
        disable: !user.disabled? && user != current_user,
        enable: user.disabled?
      }.select { |_action, visible| visible }.keys
    end

    def localized_datetime(value)
      value ? l(value, format: :long) : t("admin.users.not_available")
    end

    def audit_event_description(event)
      t("admin.audit.events.#{event.event_type}", actor: event.actor.full_name)
    end
  end
end
