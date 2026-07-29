module Admin
  module Guardians
    class Transition < ::Guardians::Operation
      def initialize(actor:, guardian:, action:)
        super()
        @actor = actor
        @guardian = guardian
        @action = action.to_sym
      end

      def call
        Guardian.transaction do
          @guardian.lock!
          target = @action == :archive ? "archived" : "active"
          if @action == :archive && active_minor_dependents?
            @guardian.errors.add(:base, :active_minor_dependency)
            return @guardian
          end
          before = @guardian.status
          return @guardian if before == target

          @guardian.status = target
          @guardian.updated_by = @actor
          @guardian.save!
          audit!(@guardian, @actor, @action.to_s.sub("archive", "archived").sub("restore", "restored"),
                 "status" => { "from" => before, "to" => target })
        end
        @guardian
      rescue ActiveRecord::RecordInvalid
        @guardian
      end

      private

      def active_minor_dependents?
        @guardian.student_guardianships.active.joins(:student_profile)
                 .exists?(student_profiles: { student_type: "minor", profile_status: "verified" })
      end
    end
  end
end
