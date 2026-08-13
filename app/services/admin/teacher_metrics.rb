module Admin
  class TeacherMetrics
    LESSON_STATUSES = %w[scheduled in_progress completed].freeze

    def initialize(profiles:, at: Time.zone.now)
      @profiles = profiles.to_a
      @at = at
    end

    def call
      ids = @profiles.map(&:id)
      return {} if ids.empty?

      assigned_counts = assigned_student_counts(ids)
      capacity_minutes = weekly_capacity_minutes(ids)
      scheduled_minutes = weekly_scheduled_minutes(ids)

      @profiles.index_with do |profile|
        capacity = capacity_minutes.fetch(profile.id, 0)
        scheduled = scheduled_minutes.fetch(profile.id, 0)
        percentage = capacity.positive? ? ((scheduled.to_f / capacity) * 100).round : 0

        {
          assigned_students_count: assigned_counts.fetch(profile.id, 0),
          capacity_minutes: capacity,
          scheduled_minutes: scheduled,
          utilization_percentage: percentage,
          utilization_bar_percentage: percentage.clamp(0, 100)
        }
      end
    end

    private

    def assigned_student_counts(ids)
      StudentProfile.where(assigned_teacher_profile_id: ids).where.not(profile_status: "archived")
                    .group(:assigned_teacher_profile_id).count
    end

    def weekly_capacity_minutes(ids)
      records = TeacherAvailability.where(teacher_profile_id: ids).active.teaching_capable
                                   .where("effective_from <= ?", week_end)
                                   .where("effective_until IS NULL OR effective_until >= ?", week_start)

      records.each_with_object(Hash.new(0)) do |availability, totals|
        duration = availability.ends_at_local.seconds_since_midnight -
                   availability.starts_at_local.seconds_since_midnight
        totals[availability.teacher_profile_id] += (duration / 60).to_i
      end
    end

    def weekly_scheduled_minutes(ids)
      rows = ScheduledLesson.where(teacher_profile_id: ids, status: LESSON_STATUSES)
                            .where(starts_at: week_window)
                            .pluck(:teacher_profile_id, :starts_at, :ends_at)

      rows.each_with_object(Hash.new(0)) do |(teacher_id, starts_at, ends_at), totals|
        totals[teacher_id] += ((ends_at - starts_at) / 60).to_i
      end
    end

    def week_start = @week_start ||= @at.to_date.beginning_of_week(:sunday)
    def week_end = @week_end ||= week_start + 6.days
    def week_window = week_start.beginning_of_day...week_end.end_of_day
  end
end
