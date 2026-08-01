module LessonAttendances
  class Adjust < Mutation
    ALLOWED_STATUSES = LessonAttendance::FINAL_STATUSES - %w[lesson_cancelled not_applicable].freeze

    def initialize(actor:, attendance:, attributes:)
      super(actor:, attendance:)
      @status = attributes[:status]
      @reason = attributes[:reason]
      @arrival_at = parse_time(attributes[:arrival_at])
      @departure_at = parse_time(attributes[:departure_at])
    end

    def call!
      unless administrator? && @reason.present? && @status.in?(ALLOWED_STATUSES)
        @attendance.errors.add(:base, :invalid_adjustment)
        raise ActiveRecord::RecordInvalid, @attendance
      end
      minutes = @arrival_at ? [((@arrival_at - @lesson.starts_at) / 60).floor, 0].max : 0
      save_with_event!({ status: @status, arrival_at: @arrival_at, departure_at: @departure_at,
                         minutes_late: minutes, adjustment_reason: @reason, last_adjusted_at: Time.current,
                         last_adjusted_by: @actor }, "adjusted", metadata: { "reason" => @reason })
    end

    private

    def parse_time(value)
      return value if value.blank? || value.respond_to?(:in_time_zone)

      ActiveSupport::TimeZone[@lesson.academy_time_zone].parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
