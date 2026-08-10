module Admin
  module Enrollments
    class Transition
      RULES = {
        approve: { from: %w[pending waitlisted], to: "approved", event: "approved" },
        waitlist: { from: %w[pending], to: "waitlisted", event: "waitlisted" },
        reject: { from: %w[pending], to: "rejected", event: "rejected" },
        activate: { from: %w[approved], to: "active", event: "activated" },
        pause: { from: %w[active], to: "paused", event: "paused" },
        resume: { from: %w[paused], to: "active", event: "resumed" },
        complete: { from: %w[active paused], to: "completed", event: "completed" },
        withdraw: { from: %w[waitlisted approved active paused], to: "withdrawn", event: "withdrawn" },
        cancel: { from: %w[pending waitlisted approved active paused], to: "cancelled", event: "cancelled" },
        transfer: { from: %w[approved active paused], to: "transferred", event: "transferred" }
      }.freeze
      ACTION_DATE_FIELDS = {
        approve: :approved_on, activate: :started_on, pause: :paused_on, resume: :resumed_on,
        complete: :completed_on, withdraw: :withdrawn_on, reject: :rejected_on, cancel: :cancelled_on
      }.freeze
      DEFAULT_EXIT_REASONS = {
        reject: "academic_mismatch", complete: "completed_program", withdraw: "student_request",
        cancel: "academy_cancelled", transfer: "transferred_to_other_offering"
      }.freeze

      def initialize(actor:, enrollment:, action:, exit_reason: nil, exit_notes: nil)
        @actor = actor
        @enrollment = enrollment
        @action = action.to_sym
        @exit_reason = exit_reason
        @exit_notes = exit_notes
      end

      # rubocop:disable Metrics/MethodLength
      def call
        rule = RULES.fetch(@action)
        Enrollment.transaction do
          @enrollment.course_offering.lock!
          @enrollment.lock!
          return invalid(:invalid_transition) unless @enrollment.status.in?(rule[:from])
          return @enrollment unless eligible?(rule[:to])

          transition!(rule)
        end
        generate_recurring_lessons if @enrollment.status.in?(%w[approved active])
        @enrollment
      rescue ActiveRecord::RecordInvalid
        @enrollment
      end
      # rubocop:enable Metrics/MethodLength

      private

      def eligible?(target)
        return approval_eligible? if target == "approved"
        return activation_eligible? if target == "active" && @action == :activate

        true
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def approval_eligible?
        profile = @enrollment.student_profile
        offering = @enrollment.course_offering
        add_error(:profile_not_ready) unless profile.profile_status.in?(%w[complete verified])
        add_error(:account_not_active) unless profile.user.active?
        add_error(:guardian_not_ready) if profile.minor? && !profile.guardian_requirements_met?
        add_error(:offering_not_open) unless offering.status == "open" && offering.accepts_new_enrollments?
        add_error(:program_not_active) unless offering.program.active?
        add_error(:capacity_full) if offering.full?
        add_error(:student_type_not_allowed) unless student_type_allowed?(profile, offering)
        add_error(:language_not_supported) unless offering.learning_language == profile.preferred_learning_language
        @enrollment.errors.empty?
      end

      def activation_eligible?
        profile = @enrollment.student_profile
        add_error(:profile_not_verified) unless profile.profile_status == "verified"
        if @enrollment.course_offering.placement_required? &&
           !@enrollment.placement_status.in?(%w[completed waived])
          add_error(:placement_incomplete)
        end
        @enrollment.errors.empty?
      end

      def student_type_allowed?(profile, offering)
        program_allowed = if profile.minor?
                            offering.program.allows_minor_students?
                          else
                            offering.program.allows_adult_students?
                          end
        eligible_groups = profile.minor? ? %w[children teenagers] : %w[adults seniors]
        program_allowed && offering.target_age_groups.intersect?(eligible_groups)
      end

      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def transition!(rule)
        before = @enrollment.status
        attributes = { status: rule[:to], updated_by: @actor }
        date_field = ACTION_DATE_FIELDS[@action]
        attributes[date_field] = Date.current if date_field
        if rule[:to].in?(Enrollment::TERMINAL_STATUSES)
          attributes.merge!(ended_on: Date.current, ended_by: @actor,
                            exit_reason: @exit_reason.presence || DEFAULT_EXIT_REASONS[@action],
                            exit_notes: @exit_notes)
        elsif rule[:to] == "approved"
          attributes[:approved_by] = @actor
        end
        @enrollment.update!(attributes)
        EnrollmentEvent.create!(
          enrollment: @enrollment, actor: @actor, event_type: rule[:event],
          metadata: { "student_public_id" => @enrollment.student_profile.public_id,
                      "offering_public_id" => @enrollment.course_offering.public_id,
                      "changes" => { "status" => { "from" => before, "to" => rule[:to] } } }
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def add_error(key)
        @enrollment.errors.add(:base, key)
      end

      def generate_recurring_lessons
        @enrollment.lesson_schedules.active.find_each do |schedule|
          EnrollmentLessonSchedules::GenerateOccurrences.new(schedule:, actor: @actor).call
        end
      end

      def invalid(key)
        add_error(key)
        @enrollment
      end
    end
  end
end
