module AcademicCatalogHelper
  def academic_badge(scope, value, variant: :neutral)
    render "shared/components/badge", label: t("academic.catalogs.#{scope}.#{value}"), variant:
  end

  def program_status_badge(program)
    variants = { "draft" => :warning, "active" => :success, "inactive" => :neutral, "archived" => :neutral }
    academic_badge(:program_statuses, program.status, variant: variants.fetch(program.status))
  end

  def offering_status_badge(offering)
    variants = { "draft" => :warning, "open" => :success, "closed" => :neutral, "in_progress" => :information,
                 "completed" => :success, "cancelled" => :danger, "archived" => :neutral }
    academic_badge(:offering_statuses, offering.status, variant: variants.fetch(offering.status))
  end

  def enrollment_status_badge(enrollment)
    variants = { "pending" => :warning, "approved" => :information, "waitlisted" => :warning,
                 "active" => :success, "paused" => :warning, "completed" => :success,
                 "withdrawn" => :neutral, "rejected" => :danger, "cancelled" => :danger,
                 "transferred" => :neutral }
    academic_badge(:enrollment_statuses, enrollment.status, variant: variants.fetch(enrollment.status))
  end

  def localized_program_name(program)
    I18n.locale == :ar ? program.name_ar : program.name_en
  end

  def localized_offering_title(offering)
    I18n.locale == :ar ? offering.title_ar : offering.title_en
  end

  def academic_value(value)
    value.presence || t("academic.not_configured")
  end

  def enrollment_actions(enrollment)
    {
      "pending" => %i[approve waitlist reject cancel],
      "waitlisted" => %i[approve withdraw cancel],
      "approved" => %i[activate withdraw cancel transfer],
      "active" => %i[pause complete withdraw cancel transfer],
      "paused" => %i[resume complete withdraw cancel transfer]
    }.fetch(enrollment.status, [])
  end
end
