module Admin
  module AcademySettings
    class Update
      AUDITED_FIELDS = AcademySetting.attribute_names.map(&:to_s).freeze -
                       %w[id singleton_key updated_by_id created_at updated_at]

      def initialize(setting:, actor:, attributes:)
        @setting = setting
        @actor = actor
        @attributes = attributes
      end

      def call
        AcademySetting.transaction do
          @setting.lock!
          @setting.assign_attributes(@attributes)
          return @setting unless @setting.valid?

          persist_changes!
        end
        @setting
      rescue ActiveRecord::RecordInvalid
        @setting
      end

      private

      def persist_changes!
        changes = @setting.changes.slice(*AUDITED_FIELDS)
        return @setting if changes.empty?

        @setting.updated_by = @actor
        @setting.save!
        AcademySettingEvent.create!(
          academy_setting: @setting, actor: @actor, event_type: "updated", metadata: serialize(changes)
        )
      end

      def serialize(changes)
        changes.transform_values do |before, after|
          { "from" => serialize_value(before), "to" => serialize_value(after) }
        end
      end

      def serialize_value(value)
        case value
        when Time, ActiveSupport::TimeWithZone then value.strftime("%H:%M")
        when BigDecimal then value.to_s("F")
        else value
        end
      end
    end
  end
end
