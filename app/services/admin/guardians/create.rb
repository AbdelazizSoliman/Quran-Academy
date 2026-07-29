module Admin
  module Guardians
    class Create < ::Guardians::Operation
      attr_reader :duplicate_candidates

      def initialize(actor:, attributes:)
        super()
        @actor = actor
        @attributes = attributes
      end

      def call
        guardian = Guardian.new(@attributes)
        guardian.created_by = guardian.updated_by = @actor
        @duplicate_candidates = duplicates_for(guardian)
        Guardian.transaction do
          guardian.save!
          audit!(guardian, @actor, "created", safe_changes(guardian))
        end
        guardian
      rescue ActiveRecord::RecordInvalid
        guardian
      end

      private

      def duplicates_for(guardian)
        terms = [guardian.email, guardian.phone_number, guardian.whatsapp_number].compact_blank
        return Guardian.none if terms.empty?

        Guardian.where("lower(email) IN (?) OR phone_number IN (?) OR whatsapp_number IN (?)",
                       terms.map(&:downcase), terms, terms)
      end
    end
  end
end
