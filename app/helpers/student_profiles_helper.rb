module StudentProfilesHelper
  def student_catalog_badge(scope, value, variant: :neutral)
    render "shared/components/badge", label: t("student_profiles.catalogs.#{scope}.#{value}"), variant:
  end

  def student_profile_status_badge(profile)
    variants = { "draft" => :warning, "complete" => :information, "verified" => :success, "archived" => :neutral }
    student_catalog_badge(:profile_statuses, profile.profile_status, variant: variants.fetch(profile.profile_status))
  end

  def student_learning_status_badge(profile)
    variants = { "prospective" => :information, "trial" => :warning, "active" => :success,
                 "paused" => :warning, "completed" => :neutral, "departed" => :danger }
    student_catalog_badge(:learning_statuses, profile.learning_status, variant: variants.fetch(profile.learning_status))
  end

  def student_value(value)
    value.presence || t("student_profiles.not_configured")
  end

  def guardian_status_badge(guardian)
    variants = { "active" => :success, "inactive" => :warning, "archived" => :neutral }
    render "shared/components/badge", label: t("guardians.catalogs.statuses.#{guardian.status}"),
                                      variant: variants.fetch(guardian.status)
  end

  def guardianship_label(link)
    return link.custom_relationship if link.relationship_type == "other"

    t("guardianships.relationships.#{link.relationship_type}")
  end
end
