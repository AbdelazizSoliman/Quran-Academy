class EffectiveTimeZone
  def self.for(user = nil)
    normalize(user&.time_zone) || normalize(academy_time_zone) || Time.zone.name
  end

  def self.normalize(value)
    ActiveSupport::TimeZone[value]&.name if value.present?
  end

  def self.academy_time_zone
    AcademySetting.current_or_nil&.default_time_zone.presence
  end
  private_class_method :academy_time_zone
end
