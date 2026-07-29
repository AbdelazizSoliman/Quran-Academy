module TeacherProfilesHelper
  STATUS_VARIANTS = {
    "draft" => :warning, "complete" => :information, "verified" => :success, "archived" => :neutral,
    "candidate" => :warning, "active" => :success, "on_leave" => :information,
    "inactive" => :neutral, "departed" => :danger
  }.freeze

  def teacher_catalog_badge(scope, value, variant: :information)
    render "shared/components/badge", label: t("teacher_profiles.catalogs.#{scope}.#{value}"), variant:
  end

  def teacher_profile_status_badge(profile)
    teacher_catalog_badge(:profile_statuses, profile.profile_status,
                          variant: STATUS_VARIANTS.fetch(profile.profile_status, :neutral))
  end

  def teacher_employment_badge(profile)
    teacher_catalog_badge(:employment_statuses, profile.employment_status,
                          variant: STATUS_VARIANTS.fetch(profile.employment_status, :neutral))
  end

  def teacher_collection(profile, attribute, scope)
    values = profile.public_send(attribute)
    return t("teacher_profiles.not_configured") if values.empty?

    safe_join(values.map { |value| teacher_catalog_badge(scope, value) }, " ")
  end

  def teacher_value(value)
    value.presence || t("teacher_profiles.not_configured")
  end

  def teacher_event_description(event)
    t("teacher_profiles.audit.#{event.event_type}", actor: event.actor.full_name)
  end
end
