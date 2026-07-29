module Admin
  module Users
    class TransitionStatus < Operation
      TRANSITIONS = {
        approve: { from: %w[pending], to: "active", event: "approved" },
        suspend: { from: %w[active], to: "suspended", event: "suspended" },
        activate: { from: %w[suspended], to: "active", event: "activated" },
        disable: { from: %w[pending active suspended], to: "disabled", event: "disabled" },
        enable: { from: %w[disabled], to: "active", event: "enabled" }
      }.freeze

      def initialize(actor:, user:, action:)
        super(actor:)
        @user = user
        @action = action.to_sym
      end

      def call
        User.transaction do
          prepare_transition!
          apply_transition!
        end
        @user
      end

      private

      def rule
        TRANSITIONS.fetch(@action)
      end

      def prepare_transition!
        lock_admins!
        @user.lock!
        raise Forbidden, :invalid_transition unless rule[:from].include?(@user.status)
        raise Forbidden, :self_lockout if @user == @actor && rule[:to] != "active"

        protect_last_admin!(@user, "status" => rule[:to])
      end

      def apply_transition!
        before = @user.status
        @user.update!(transition_attributes)
        audit!(@user, rule[:event], change_metadata("status" => [before, rule[:to]]))
      end

      def transition_attributes
        attributes = { status: rule[:to] }
        attributes.merge!(approved_at: Time.current, approved_by: @actor) if @action == :approve
        attributes[:session_version] = @user.session_version + 1 if rule[:to] != "active"
        attributes
      end
    end
  end
end
