module Admin
  module ScheduledLessons
    class Transition < Create
      RULES = {
        schedule: { from: %w[draft], to: "scheduled", event: "scheduled" },
        start: { from: %w[scheduled], to: "in_progress", event: "started" },
        complete: { from: %w[in_progress], to: "completed", event: "completed" },
        cancel: { from: %w[draft scheduled in_progress], to: "cancelled", event: "cancelled" },
        archive: { from: %w[draft scheduled completed cancelled], to: "archived", event: "archived" }
      }.freeze

      def initialize(actor:, lesson:, action:, cancellation_reason: nil)
        super(actor:, attributes: {})
        @lesson = lesson
        @action = action.to_sym
        @cancellation_reason = cancellation_reason
      end

      def call
        rule = RULES.fetch(@action)
        error = precondition_error(rule)
        return error if error

        ScheduledLesson.transaction do
          perform_transition(rule)
        end
        @lesson
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
        @lesson.errors.add(:base, :stale_record) if @lesson.errors.empty?
        @lesson
      end

      private

      def precondition_error(rule)
        return invalid(:invalid_transition) unless @lesson.status.in?(rule[:from])

        invalid(:cancellation_reason_required) if cancelling_without_reason?
      end

      def perform_transition(rule)
        @lesson.lock!
        return invalid(:stale_record) unless @lesson.status.in?(rule[:from])
        return invalid(:conflict) unless eligible_for_schedule?

        previous_status = @lesson.status
        @lesson.update!(transition_attributes(rule))
        create_event(rule, previous_status)
      end

      def transition_attributes(rule)
        attributes = { status: rule[:to], updated_by: @actor }
        attributes.merge!(cancellation_attributes) if @action == :cancel
        attributes[:completed_at] = Time.current if @action == :complete
        attributes
      end

      def cancellation_attributes
        { cancellation_reason: @cancellation_reason, cancelled_at: Time.current, cancelled_by: @actor }
      end

      def create_event(rule, previous_status)
        ScheduledLessonEvent.create!(scheduled_lesson: @lesson, actor: @actor, event_type: rule[:event],
                                     before_data: { "status" => previous_status },
                                     after_data: { "status" => rule[:to] })
      end

      def eligible_for_schedule?
        return true unless @action == :schedule

        unless teacher_usable?
          @lesson.errors.add(:base, :teacher_unavailable)
          return false
        end

        check_availability
        check_conflicts
        offering_usable? && @lesson.errors.empty?
      end

      def check_availability
        result = TeacherScheduling::AvailabilityCheck.call(
          teacher_profile: @lesson.teacher_profile, starts_at: @lesson.starts_at, ends_at: @lesson.ends_at,
          academy_time_zone: @lesson.academy_time_zone
        )
        return if result.available?

        @lesson.errors.add(:base, :teacher_unavailable, reasons: result.conflict_reasons.join(", "))
      end

      def check_conflicts
        result = Scheduling::ConflictCheck.call(
          lesson: @lesson, starts_at: @lesson.starts_at, ends_at: @lesson.ends_at,
          teacher_profile: @lesson.teacher_profile, enrollment_ids: @lesson.enrollments.ids
        )
        @lesson.errors.add(:base, :schedule_conflict) if result.conflicts?
      end

      def cancelling_without_reason?
        @action == :cancel && @cancellation_reason.blank?
      end

      def teacher_usable?
        profile = @lesson.teacher_profile
        profile&.employment_status == "active" && !profile.archived?
      end

      def offering_usable?
        @lesson.course_offering.status != "cancelled" && !@lesson.course_offering.archived?
      end

      def invalid(error)
        @lesson.errors.add(:base, error)
        @lesson
      end
    end
  end
end
