module Admin
  module StudentGuardianships
    class CreateGuardianAndAttach
      attr_reader :guardian, :guardianship

      def initialize(actor:, student_profile:, guardian_attributes:, relationship_attributes:)
        @actor = actor
        @student_profile = student_profile
        @guardian_attributes = guardian_attributes
        @relationship_attributes = relationship_attributes
      end

      def call
        Guardian.transaction do
          @guardian = Guardians::Create.new(actor: @actor, attributes: @guardian_attributes).call
          raise ActiveRecord::Rollback unless @guardian.persisted?

          @guardianship = Create.new(
            actor: @actor, student_profile: @student_profile, guardian: @guardian,
            attributes: @relationship_attributes
          ).call
          raise ActiveRecord::Rollback unless @guardianship.persisted?
        end
        self
      end

      def success?
        guardian&.persisted? && guardianship&.persisted?
      end
    end
  end
end
