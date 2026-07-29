module Admin
  module TeacherProfiles
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
        changes = audited_changes(@profile, ADMIN_FIELDS)
        return @profile if changes.empty?

        @profile.updated_by = @actor
        @profile.save!
        audit!(@profile, @actor, event_type(changes), changes)
      end

      def event_type(changes)
        return "compensation_changed" if changes.keys.intersect?(COMPENSATION_FIELDS)
        return "employment_status_changed" if changes.key?("employment_status")
        return "engagement_type_changed" if changes.key?("engagement_type")

        "updated"
      end
    end
  end
end
