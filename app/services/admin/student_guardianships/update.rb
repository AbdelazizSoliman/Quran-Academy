module Admin
  module StudentGuardianships
    class Update < ::StudentGuardianships::Operation
      def initialize(actor:, guardianship:, attributes:)
        super()
        @actor = actor
        @link = guardianship
        @attributes = attributes
      end

      def call
        ::StudentGuardianship.transaction do
          @link.lock!
          @link.assign_attributes(@attributes.except("primary_contact"))
          return @link unless @link.valid?

          changes = safe_changes(@link)
          return @link if changes.empty?

          @link.updated_by = @actor
          @link.save!
          event = if changes.keys.intersect?(%w[legal_guardian can_make_academic_decisions])
                    "legal_authority_changed"
                  else
                    "updated"
                  end
          audit!(@link, @actor, event, changes)
        end
        @link
      rescue ActiveRecord::RecordInvalid
        @link
      end
    end
  end
end
