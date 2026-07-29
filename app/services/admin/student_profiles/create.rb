module Admin
  module StudentProfiles
    class Create < ::StudentProfiles::Operation
      def initialize(actor:, user:, attributes:)
        super()
        @actor = actor
        @user = user
        @attributes = attributes
      end

      def call
        profile = @user.build_student_profile(@attributes)
        profile.created_by = profile.updated_by = @actor
        StudentProfile.transaction do
          profile.save!
          audit!(profile, @actor, "created", safe_changes(profile, ADMIN_FIELDS))
        end
        profile
      rescue ActiveRecord::RecordInvalid
        profile
      end
    end
  end
end
