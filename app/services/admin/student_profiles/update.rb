module Admin
  module StudentProfiles
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

          changes = safe_changes(@profile, ADMIN_FIELDS)
          return @profile if changes.empty?

          @profile.updated_by = @actor
          @profile.save!
          event = if changes.keys.intersect?(StudentProfile::SENSITIVE_FIELDS)
                    "sensitive_information_updated"
                  elsif changes.key?("learning_status")
                    "learning_status_changed"
                  elsif changes.key?("student_type")
                    "student_type_changed"
                  else
                    "updated"
                  end
          audit!(@profile, @actor, event, changes)
        end
        @profile
      rescue ActiveRecord::RecordInvalid
        @profile
      end
    end
  end
end
