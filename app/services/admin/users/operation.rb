module Admin
  module Users
    class Operation
      class Forbidden < StandardError
        attr_reader :reason

        def initialize(reason)
          @reason = reason
          super(reason.to_s)
        end
      end

      SAFE_FIELDS = %w[first_name last_name email role status preferred_locale time_zone
                       account_delivery_method].freeze

      def initialize(actor:)
        @actor = actor
      end

      private

      def audit!(target, event_type, changes = {})
        UserAccountEvent.create!(
          target_user: target,
          actor: @actor,
          event_type:,
          metadata: changes.slice(*SAFE_FIELDS)
        )
      end

      def lock_admins!
        User.admin.lock.load
      end

      def protect_self!(target, attributes)
        return unless target == @actor
        return unless attributes.key?("role") && attributes["role"].to_s != "admin"

        raise Forbidden, :self_demotion
      end

      def protect_last_admin!(target, attributes)
        return unless target.admin? && target.active?
        return unless removes_active_admin?(attributes)
        return unless User.admin.active.count <= 1

        raise Forbidden, :last_admin
      end

      def removes_active_admin?(attributes)
        (attributes["role"].present? && attributes["role"].to_s != "admin") ||
          (attributes["status"].present? && attributes["status"].to_s != "active")
      end

      def change_metadata(changes)
        changes.transform_values { |before, after| { "from" => before, "to" => after } }
      end
    end
  end
end
