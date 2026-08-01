module LessonAttendances
  class Mutation
    AUDIT_FIELDS = %w[status arrival_at departure_at minutes_late excuse_reason recorded_at adjustment_reason].freeze

    def initialize(actor:, attendance:)
      @actor = actor
      @attendance = attendance
      @lesson = attendance.scheduled_lesson
    end

    def call
      LessonAttendance.transaction { call! }
      @attendance
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      @attendance.errors.add(:base, :stale_record) if @attendance.errors.empty?
      @attendance
    end

    private

    def ensure_editable!
      return if @lesson.attendance_editable?

      @attendance.errors.add(:base, :attendance_locked)
      raise ActiveRecord::RecordInvalid, @attendance
    end

    def save_with_event!(attributes, event_type, metadata: {})
      ensure_editable!
      before = @attendance.attributes.slice(*AUDIT_FIELDS)
      @attendance.assign_attributes(attributes)
      changes = @attendance.changes.slice(*AUDIT_FIELDS)
      return @attendance if changes.empty?

      @attendance.save!
      LessonAttendanceEvent.create!(lesson_attendance: @attendance, actor: @actor, event_type:,
                                    before_data: before.slice(*changes.keys),
                                    after_data: @attendance.attributes.slice(*changes.keys), metadata:)
      @attendance
    end

    def administrator? = @actor.active? && @actor.admin?
  end
end
