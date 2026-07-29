module Admin
  module StudentProfiles
    class Transition < ::StudentProfiles::Operation
      RULES = {
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
        rule = RULES.fetch(@action)
        StudentProfile.transaction do
          @profile.lock!
          unless @profile.profile_status.in?(rule[:from])
            @profile.errors.add(:profile_status, :invalid_transition)
            return @profile
          end
          before = @profile.profile_status
          @profile.profile_status = rule[:to]
          @profile.updated_by = @actor
          @profile.save!
          audit!(@profile, @actor, rule[:event], "profile_status" => { "from" => before, "to" => rule[:to] })
        end
        @profile
      rescue ActiveRecord::RecordInvalid
        @profile
      end
    end
  end
end
