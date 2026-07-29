module Teacher
  module Profiles
    class Update < ::TeacherProfiles::Operation
      def initialize(actor:, profile:, attributes:)
        super()
        @actor = actor
        @profile = profile
        @attributes = attributes
      end

      def call
        TeacherProfile.transaction do
          @profile.lock!
          @profile.assign_attributes(@attributes)
          return @profile unless @profile.valid?

          persist_changes!
        end
        @profile
      rescue ActiveRecord::RecordInvalid
        @profile
      end

      private

      def persist_changes!
        changes = audited_changes(@profile, SELF_FIELDS)
        return @profile if changes.empty?

        @profile.updated_by = @actor
        @profile.save!
        audit!(@profile, @actor, "self_updated", changes)
      end
    end
  end
end
