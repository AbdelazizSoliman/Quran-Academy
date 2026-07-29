module Admin
  module TeacherProfiles
    class Transition < ::TeacherProfiles::Operation
      TRANSITIONS = {
        verify: { from: %w[draft complete verified], to: "verified", event: "verified" },
        archive: { from: %w[draft complete verified], to: "archived", event: "archived" },
        restore: { from: %w[archived], to: "draft", event: "restored" }
      }.freeze

      def initialize(actor:, profile:, action:)
        super()
        @actor = actor
        @profile = profile
        @action = action.to_sym
      end

      def call
        rule = TRANSITIONS.fetch(@action)
        TeacherProfile.transaction do
          @profile.lock!
          return invalid_transition unless @profile.profile_status.in?(rule[:from])

          apply_transition!(rule)
        end
        @profile
      rescue ActiveRecord::RecordInvalid
        @profile
      end

      private

      def invalid_transition
        @profile.errors.add(:profile_status, :invalid_transition)
        @profile
      end

      def apply_transition!(rule)
        before = @profile.profile_status
        @profile.profile_status = rule[:to]
        @profile.updated_by = @actor
        @profile.save!
        audit!(@profile, @actor, rule[:event], "profile_status" => { "from" => before, "to" => rule[:to] })
      end
    end
  end
end
