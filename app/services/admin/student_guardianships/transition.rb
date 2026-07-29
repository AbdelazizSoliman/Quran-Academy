module Admin
  module StudentGuardianships
    class Transition < ::StudentGuardianships::Operation
      def initialize(actor:, guardianship:, action:, replacement_id: nil)
        super()
        @actor = actor
        @link = guardianship
        @action = action.to_sym
        @replacement_id = replacement_id
      end

      def call
        ::StudentGuardianship.transaction do
          @link.student_profile.lock!
          case @action
          when :make_primary then make_primary!
          when :end then end_link!
          when :restore then restore!
          end
        end
        @link
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        @link.errors.add(:base, :transition_failed) if @link.errors.empty?
        @link
      end

      private

      def make_primary!
        before = @link.primary_contact
        return if before && @link.active?

        @link.student_profile.student_guardianships.active.where(primary_contact: true)
             .where.not(id: @link.id).update_all(primary_contact: false, updated_at: Time.current)
        @link.update!(primary_contact: true, status: "active", updated_by: @actor)
        audit!(@link, @actor, "made_primary", "primary_contact" => { "from" => before, "to" => true })
      end

      def end_link!
        if @link.primary_contact? && verified_minor? && replacement.blank?
          @link.errors.add(:primary_contact, :replacement_required)
          raise ActiveRecord::Rollback
        end
        replacement && self.class.new(actor: @actor, guardianship: replacement, action: :make_primary).call
        before = @link.status
        @link.update!(status: "ended", ends_on: Date.current, primary_contact: false, updated_by: @actor)
        audit!(@link, @actor, "ended", "status" => { "from" => before, "to" => "ended" })
      end

      def restore!
        before = @link.status
        @link.update!(status: "active", ends_on: nil, primary_contact: false, updated_by: @actor)
        audit!(@link, @actor, "restored", "status" => { "from" => before, "to" => "active" })
      end

      def verified_minor?
        @link.student_profile.minor? && @link.student_profile.profile_status == "verified"
      end

      def replacement
        return @replacement if defined?(@replacement)

        @replacement = @link.student_profile.student_guardianships.active.find_by(id: @replacement_id)
      end
    end
  end
end
