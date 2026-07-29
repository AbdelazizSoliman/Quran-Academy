module Admin
  module StudentGuardianships
    class Create < ::StudentGuardianships::Operation
      def initialize(actor:, student_profile:, guardian:, attributes:)
        super()
        @actor = actor
        @student_profile = student_profile
        @guardian = guardian
        @attributes = attributes
      end

      def call
        link = @student_profile.student_guardianships.build(@attributes.merge(guardian: @guardian))
        link.created_by = link.updated_by = @actor
        ::StudentGuardianship.transaction do
          clear_primary! if link.primary_contact?
          link.save!
          audit!(link, @actor, "created", safe_changes(link))
        end
        link
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        link.errors.add(:primary_contact, :already_exists) if link.errors.empty?
        link
      end

      private

      def clear_primary!
        @student_profile.lock!
        @student_profile.student_guardianships.active.where(primary_contact: true)
                        .update_all(primary_contact: false, updated_at: Time.current) # deliberate atomic switch
      end
    end
  end
end
