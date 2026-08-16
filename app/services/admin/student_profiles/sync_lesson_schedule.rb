module Admin
  module StudentProfiles
    class SyncLessonSchedule
      attr_reader :schedule

      def initialize(actor:, profile:)
        @actor = actor
        @profile = profile
      end

      def call
        return unless scheduling_complete?

        @schedule = active_schedule ? replace_schedule : create_schedule
        merge_errors
        @schedule
      end

      private

      def active_schedule
        @active_schedule ||= EnrollmentLessonSchedule.active.left_joins(:enrollment)
                                                     .where(
                                                       "enrollment_lesson_schedules.student_profile_id = :profile_id " \
                                                       "OR enrollments.student_profile_id = :profile_id",
                                                       profile_id: @profile.id
                                                     ).order(:created_at).last
      end

      def replace_schedule
        effective_on = [Date.current + 1.day, active_schedule.starts_on + 1.day].max
        EnrollmentLessonSchedules::Change.new(
          actor: @actor, schedule: active_schedule, effective_on:,
          attributes: schedule_attributes(starts_on: effective_on), slots:
        ).call
      end

      def create_schedule
        enrollment = current_enrollment
        student_profile = direct_student_profile(enrollment)
        return unless enrollment || student_profile

        starts_on = [enrollment&.course_offering&.planned_start_on || Date.current, Date.current].max
        EnrollmentLessonSchedules::Create.new(
          actor: @actor, enrollment:, student_profile:,
          attributes: schedule_attributes(starts_on:), slots:
        ).call
      end

      def direct_student_profile(enrollment)
        @profile if enrollment.nil? && @profile.fee_plan_id.present?
      end

      def schedule_attributes(starts_on:)
        {
          teacher_profile: @profile.assigned_teacher_profile,
          starts_on:, ends_on: generation_ends_on(starts_on),
          lesson_duration_minutes: @profile.lesson_duration_minutes,
          time_zone: EffectiveTimeZone.for(@profile.user), status: "active"
        }
      end

      def generation_ends_on(starts_on)
        weeks = @profile.schedule_generation_weeks.to_i
        generated_end = starts_on + weeks.weeks if weeks.positive?
        offering_end = current_enrollment&.course_offering&.planned_end_on
        [generated_end, offering_end].compact.min
      end

      def current_enrollment
        @current_enrollment ||= @profile.enrollments.where.not(status: Enrollment::TERMINAL_STATUSES)
                                        .recent_first.first
      end

      def slots
        @slots ||= Array(@profile.schedule_slots).filter_map do |slot|
          values = slot.to_h.stringify_keys
          next if values["weekday"].blank? || values["time"].blank?

          { weekday: values.fetch("weekday"), starts_at_local: values.fetch("time") }
        end
      end

      def scheduling_complete?
        @profile.assigned_teacher_profile.present? && @profile.lesson_duration_minutes.present? && slots.any?
      end

      def merge_errors
        return unless @schedule&.errors&.any?

        @schedule.errors.full_messages.each { |message| @profile.errors.add(:base, message) }
      end
    end
  end
end
