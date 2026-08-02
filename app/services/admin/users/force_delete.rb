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
          delete_notifications
          delete_invitation
          delete_profile
          UserAccountEvent.where(target_user: @user).or(UserAccountEvent.where(actor: @user)).delete_all
          @user.delete
        end
        true
      rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
        raise Forbidden, :operational_history
      end

      private

      def authorized?
        @actor.active? && @actor.admin? && @actor.email.to_s.casecmp?(PRIVILEGED_EMAIL)
      end

      def delete_notifications
        scope = Notification.where(recipient_user: @user).or(Notification.where(actor: @user))
        scope.find_each do |notification|
          notification.attempts.delete_all
          notification.events.delete_all
          notification.delete
        end
      end

      def delete_invitation
        invitations = AccountInvitation.where(user: @user).or(AccountInvitation.where(created_by: @user))
        invitations.find_each do |invitation|
          invitation.events.delete_all
          invitation.delete
        end
      end

      def delete_profile
        profile = @user.teacher_profile || @user.student_profile || @user.staff_profile
        return unless profile

        profile.events.delete_all if profile.respond_to?(:events)
        profile.destroy!
      end
    end
  end
end
