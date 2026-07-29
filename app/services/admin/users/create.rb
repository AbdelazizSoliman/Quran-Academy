module Admin
  module Users
    class Create < Operation
      def initialize(actor:, attributes:)
        super(actor:)
        @attributes = attributes
      end

      def call
        user = User.new(@attributes)
        user.status ||= :active
        user.preferred_locale = nil if @attributes[:preferred_locale].blank?

        User.transaction do
          user.save!
          audit!(user, "created", change_metadata(user.previous_changes.slice(*SAFE_FIELDS)))
        end
        user
      rescue ActiveRecord::RecordInvalid
        user
      end
    end
  end
end
