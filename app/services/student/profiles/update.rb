module Student
  module Profiles
    class Update < ::StudentProfiles::Operation
      def initialize(actor:, profile:, attributes:)
        super()
        @actor = actor
        @profile = profile
        @attributes = attributes
      end

      def call
        StudentProfile.transaction do
          @profile.lock!
          @profile.assign_attributes(@attributes)
          return @profile unless @profile.valid?

          changes = safe_changes(@profile, SELF_FIELDS)
          return @profile if changes.empty?

          @profile.updated_by = @actor
          @profile.save!
          audit!(@profile, @actor, "self_updated", changes)
        end
        @profile
      rescue ActiveRecord::RecordInvalid
        @profile
      end
    end
  end
end
