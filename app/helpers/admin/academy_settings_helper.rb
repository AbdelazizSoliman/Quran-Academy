module Admin
  module AcademySettingsHelper
    def setting_value(value)
      value.presence || t("admin.settings.not_configured")
    end

    def setting_boolean_badge(value)
      render "shared/components/badge",
             label: t("admin.settings.boolean.#{value ? 'enabled' : 'disabled'}"),
             variant: value ? :success : :neutral
    end

    def setting_collection_badges(values, scope)
      safe_join(Array(values).map do |value|
        render("shared/components/badge", label: t("#{scope}.#{value}"), variant: :information)
      end, " ")
    end

    def setting_time(value)
      value ? value.strftime("%H:%M") : t("admin.settings.not_configured")
    end

    def audit_setting_description(event)
      fields = event.metadata.keys.map { |field| t("admin.settings.fields.#{field}") }.to_sentence
      t("admin.settings.audit.updated", actor: event.actor.full_name, fields:)
    end
  end
end
