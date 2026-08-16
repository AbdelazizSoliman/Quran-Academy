module TeacherScheduling
  AvailabilityResult = Data.define(:available?, :recurring_match, :override_match, :blocking_exception,
                                   :conflict_reasons, :academy_range, :teacher_range)

  class AvailabilityCheck
    def self.call(...)
      new(...).call
    end

    def initialize(teacher_profile:, starts_at:, ends_at:, academy_time_zone: nil)
      @teacher_profile = teacher_profile
      @starts_at = starts_at
      @ends_at = ends_at
      @academy_time_zone = EffectiveTimeZone.normalize(academy_time_zone) || EffectiveTimeZone.for
    end

    def call
      prepare_context
      recurring = matching_recurring || work_days_match?
      exceptions = matching_exceptions
      unavailable = exceptions.any? { |exception| exception.exception_type == "unavailable" }
      override = exceptions.any? { |exception| exception.exception_type == "available_override" }
      matched = recurring || override
      build_result(recurring, override, unavailable, matched)
    end

    private

    def build_result(recurring, override, unavailable, matched)
      AvailabilityResult.new(
        matched && !unavailable, recurring, override, unavailable, conflict_reasons(matched, unavailable),
        [@starts_at.in_time_zone(@academy_time_zone), @ends_at.in_time_zone(@academy_time_zone)],
        [@teacher_start, @teacher_end]
      )
    end

    def teacher_zone
      EffectiveTimeZone.for(@teacher_profile.user)
    end

    def prepare_context
      zone = ActiveSupport::TimeZone[teacher_zone]
      @teacher_start = @starts_at.in_time_zone(zone)
      @teacher_end = @ends_at.in_time_zone(zone)
      @date = @teacher_start.to_date
      @weekday = @teacher_start.strftime("%A").downcase
    end

    def matching_recurring
      recurring_windows.any? do |record|
        record.weekday == local_weekday(record.time_zone) &&
          effective_on_date?(record) && contains_lesson?(record)
      end
    end

    def recurring_windows
      @teacher_profile.availabilities.active.teaching_capable
    end

    def effective_on_date?(record)
      date = local_date(record.time_zone)
      record.effective_from <= date && (record.effective_until.nil? || record.effective_until >= date)
    end

    def contains_lesson?(record)
      start_seconds, end_seconds = local_seconds(record.time_zone)
      record.starts_at_local.seconds_since_midnight <= start_seconds &&
        record.ends_at_local.seconds_since_midnight >= end_seconds
    end

    # A teacher's selected work_days are a simpler, coarser recurring-availability source than
    # TeacherAvailability records. A blank work_start_time/work_end_time pair means "available all
    # day" on that selected day, per the onboarding business rule — never "unavailable".
    def work_days_match?
      return false unless @teacher_profile.work_days.include?(@weekday)
      return true if @teacher_profile.work_start_time.blank? && @teacher_profile.work_end_time.blank?

      start_seconds, end_seconds = local_seconds(teacher_zone)
      @teacher_profile.work_start_time.seconds_since_midnight <= start_seconds &&
        @teacher_profile.work_end_time.seconds_since_midnight >= end_seconds
    end

    def matching_exceptions
      exceptions_on_date.select do |exception|
        exception.starts_at_local.blank? || overlaps_lesson?(exception)
      end
    end

    def exceptions_on_date
      @teacher_profile.availability_exceptions.active.select do |exception|
        exception.exception_date == local_date(exception.time_zone)
      end
    end

    def overlaps_lesson?(exception)
      start_seconds, end_seconds = local_seconds(exception.time_zone)
      exception.starts_at_local.seconds_since_midnight < end_seconds &&
        exception.ends_at_local.seconds_since_midnight > start_seconds
    end

    def local_seconds(time_zone)
      zone = ActiveSupport::TimeZone[time_zone]
      [@starts_at.in_time_zone(zone).seconds_since_midnight, @ends_at.in_time_zone(zone).seconds_since_midnight]
    end

    def local_date(time_zone)
      @starts_at.in_time_zone(time_zone).to_date
    end

    def local_weekday(time_zone)
      @starts_at.in_time_zone(time_zone).strftime("%A").downcase
    end

    def conflict_reasons(matched, unavailable)
      reasons = []
      reasons << :outside_recurring_availability unless matched
      reasons << :unavailable_exception if unavailable
      reasons
    end
  end
end
