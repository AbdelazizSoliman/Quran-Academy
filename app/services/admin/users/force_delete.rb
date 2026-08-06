module Admin
  module Users
    class ForceDelete < Operation
      PRIVILEGED_EMAIL = "abdelaziz.soliman89@gmail.com".freeze

      def initialize(actor:, user:)
        super(actor:)
        @user = user
      end

      def call
        raise Forbidden, :force_delete_forbidden unless authorized?
        raise Forbidden, :self_delete if @user == @actor

        User.transaction do
          CascadingDelete.new(table: "users", ids: [@user.id]).call
        end
        true
      rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
        raise Forbidden, :operational_history
      end

      private

      def authorized?
        @actor.active? && @actor.admin? && @actor.email.to_s.casecmp?(PRIVILEGED_EMAIL)
      end
    end
  end
end
