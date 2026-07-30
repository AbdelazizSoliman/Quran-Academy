module Admin
  module Enrollments
    class Placement
      def initialize(actor:, enrollment:, action:, method: nil, notes: nil)
        @actor = actor
        @enrollment = enrollment
        @action = action.to_sym
        @method = method
        @notes = notes
      end

      # rubocop:disable Metrics/MethodLength
      def call
        target = @action == :complete_placement ? "completed" : "waived"
        event = @action == :complete_placement ? "placement_completed" : "placement_waived"
        if @action == :waive_placement && @notes.blank?
          @enrollment.errors.add(:placement_notes, :required_for_waiver)
          return @enrollment
        end
        Enrollment.transaction do
          @enrollment.lock!
          unless @enrollment.placement_status.in?(%w[pending in_review])
            @enrollment.errors.add(:placement_status, :invalid_transition)
            return @enrollment
          end
          before = @enrollment.placement_status
          @enrollment.update!(placement_status: target, placement_method: @method,
                              placement_notes: @notes, placement_completed_on: Date.current,
                              updated_by: @actor)
          EnrollmentEvent.create!(
            enrollment: @enrollment, actor: @actor, event_type: event,
            metadata: { "changes" => { "placement_status" => { "from" => before, "to" => target },
                                       "placement_notes" => { "changed" => @notes.present? } } }
          )
        end
        @enrollment
      rescue ActiveRecord::RecordInvalid
        @enrollment
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
