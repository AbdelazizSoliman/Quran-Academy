module Admin
  module Guardians
    class Update < ::Guardians::Operation
      def initialize(actor:, guardian:, attributes:)
        super()
        @actor = actor
        @guardian = guardian
        @attributes = attributes
      end

      def call
        Guardian.transaction do
          @guardian.lock!
          @guardian.assign_attributes(@attributes)
          return @guardian unless @guardian.valid?

          changes = safe_changes(@guardian)
          return @guardian if changes.empty?

          @guardian.updated_by = @actor
          @guardian.save!
          event = if changes.keys.intersect?(%w[email phone_number whatsapp_number preferred_contact_method])
                    "contact_information_changed"
                  else
                    "updated"
                  end
          audit!(@guardian, @actor, event, changes)
        end
        @guardian
      rescue ActiveRecord::RecordInvalid
        @guardian
      end
    end
  end
end
