module Admin
  module Users
    class Create < Operation
      def initialize(actor:, attributes:)
        super(actor:)
        @attributes = attributes
      end

      def call
        user = build_user

        User.transaction do
          user.save!
          audit!(user, "created", change_metadata(user.previous_changes.slice(*SAFE_FIELDS)))
          AccountInvitations::CreateAndSend.new(user:, actor: @actor).call
        end
        user
      rescue ActiveRecord::RecordInvalid
        user
      end

      private

      def build_user
        user = User.new(@attributes)
        user.status = :pending
        user.preferred_locale = nil if @attributes[:preferred_locale].blank?
        password = SecureRandom.base64(48)
        user.password = user.password_confirmation = password
        user
      end
    end
  end
end
