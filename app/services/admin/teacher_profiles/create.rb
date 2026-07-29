module Admin
  module TeacherProfiles
    class Create < ::TeacherProfiles::Operation
      def initialize(actor:, user:, attributes:)
        super()
        @actor = actor
        @user = user
        @attributes = attributes
      end

      def call
        profile = @user.build_teacher_profile(@attributes)
        profile.created_by = @actor
        profile.updated_by = @actor
        TeacherProfile.transaction do
          profile.save!
          audit!(profile, @actor, "created", audited_changes(profile, ADMIN_FIELDS))
        end
        profile
      rescue ActiveRecord::RecordInvalid
        profile
      end
    end
  end
end
