module Admin
  module Users
    class ForceDelete < Operation
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
        @actor.active? && @actor.admin?
      end
    end
  end
end
