module SchedulingHelper
  def scheduling_status_badge(record)
    variants = { draft: :warning, scheduled: :success, in_progress: :information, completed: :success,
                 cancelled: :danger, archived: :neutral }
    render "shared/components/badge", label: t("scheduling.catalogs.statuses.#{record.status}"),
                                      variant: variants.fetch(record.status.to_sym, :neutral)
  end

  def scheduling_time(time, zone: Time.zone)
    return t("scheduling.not_configured") unless time

    "#{l(time.in_time_zone(zone), format: :short)} (#{zone.name})"
  end
end
