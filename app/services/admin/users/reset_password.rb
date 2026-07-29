module Admin
  module Users
    class ResetPassword < Operation
      def initialize(actor:, user:, password:, password_confirmation:)
        super(actor:)
        @user = user
        @password = password
        @password_confirmation = password_confirmation
      end

      def call
        User.transaction do
          reset_password!
        end
        @user
      rescue ActiveRecord::RecordInvalid
        @user.password = @user.password_confirmation = nil
        @user
      ensure
        @password = @password_confirmation = nil
      end

      private

      def reset_password!
        @user.lock!
        @user.password = @password
        @user.password_confirmation = @password_confirmation
        @user.session_version += 1
        @user.save!
        audit!(@user, "password_reset")
      end
    end
  end
end
