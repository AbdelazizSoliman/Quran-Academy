module Admin
  module Users
    class Update < Operation
      def initialize(actor:, user:, attributes:)
        super(actor:)
        @user = user
        @attributes = attributes.to_h.stringify_keys
      end

      def call
        User.transaction do
          prepare_change!
          persist_change!
        end
        @user
      rescue ActiveRecord::RecordInvalid
        @user
      end

      private

      def prepare_change!
        lock_admins!
        @user.lock!
        protect_self!(@user, @attributes)
        protect_last_admin!(@user, @attributes)
        @user.assign_attributes(@attributes)
      end

      def persist_change!
        changes = @user.changes.slice(*SAFE_FIELDS)
        return if changes.empty?

        @user.save!
        role_change = changes.delete("role")
        audit!(@user, "updated", change_metadata(changes)) if changes.any?
        audit!(@user, "role_changed", change_metadata("role" => role_change)) if role_change
      end
    end
  end
end
