module Scheduling
  ConflictResult = Data.define(:conflicts?, :teacher_conflicts, :student_conflicts)

  class ConflictCheck
    def self.call(...)
      new(...).call
    end

    def initialize(lesson:, starts_at:, ends_at:, teacher_profile:, enrollment_ids:)
      @lesson = lesson
      @starts_at = starts_at
      @ends_at = ends_at
      @teacher_profile = teacher_profile
      @enrollment_ids = Array(enrollment_ids).compact
    end

    def call
      ConflictResult.new(teacher_conflicts.any? || student_conflicts.any?, teacher_conflicts, student_conflicts)
    end

    private

    def overlap(scope)
      scope.where.not(id: @lesson.id).where(status: ScheduledLesson::OPERATIONAL_STATUSES)
           .where("starts_at < :ends_at AND ends_at > :starts_at", starts_at: @starts_at, ends_at: @ends_at)
    end

    def teacher_conflicts
      overlap(@teacher_profile.scheduled_lessons).to_a
    end

    def student_conflicts
      return [] if @enrollment_ids.empty?

      student_ids = Enrollment.where(id: @enrollment_ids).distinct.pluck(:student_profile_id)
      ScheduledLesson.joins(scheduled_lesson_enrollments: :enrollment)
                     .where(enrollments: { student_profile_id: student_ids })
                     .where.not(id: @lesson.id)
                     .where(status: ScheduledLesson::OPERATIONAL_STATUSES)
                     .where("scheduled_lessons.starts_at < :ends_at AND scheduled_lessons.ends_at > :starts_at",
                            starts_at: @starts_at, ends_at: @ends_at).distinct.to_a
    end
  end
end
