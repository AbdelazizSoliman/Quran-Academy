module Admin
  module ScheduledLessons
    class Create < Admin::SchedulingOperation
      FIELDS = %w[course_offering_id teacher_profile_id title_ar title_en starts_at ends_at academy_time_zone
                  delivery_mode location_name online_meeting_url scheduling_source
                  enrollment_lesson_schedule_slot_id recurrence_date].freeze

      def initialize(actor:, attributes:)
        super()
        @actor = actor
        @attributes = attributes
      end

      def call
        lesson = ScheduledLesson.new(normalize_attributes)
        lesson.created_by = lesson.updated_by = @actor
        ScheduledLesson.transaction do
          lesson.save!
          ScheduledLessonEvent.create!(scheduled_lesson: lesson, actor: @actor, event_type: "created",
                                       after_data: lesson.attributes.slice(*FIELDS))
        end
        lesson
      rescue ActiveRecord::RecordInvalid
        lesson
      end

      private

      def normalize_attributes
        attributes = @attributes.to_h.symbolize_keys
        zone = persisted_academy_zone || attributes[:academy_time_zone].presence ||
               AcademySetting.current_or_nil&.default_time_zone || "Cairo"
        attributes.merge(academy_time_zone: zone,
                         starts_at: parse_datetime(attributes[:starts_at], zone),
                         ends_at: parse_datetime(attributes[:ends_at], zone))
      end

      def persisted_academy_zone
        @lesson.academy_time_zone if defined?(@lesson) && @lesson&.persisted?
      end

      def parse_datetime(value, zone)
        return value if value.blank? || value.respond_to?(:in_time_zone)

        ActiveSupport::TimeZone[zone].parse(value.to_s)
      rescue ArgumentError
        value
      end
    end
  end
end
