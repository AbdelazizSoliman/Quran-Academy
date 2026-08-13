module Scheduling
  ConflictResult = Data.define(:conflicts?, :teacher_conflicts, :student_conflicts)

  class ConflictCheck
    def self.call(...)
      new(...).call
    end

    # rubocop:disable Metrics/ParameterLists -- student_profile_ids covers direct (enrollment-less)
    # participants alongside enrollment_ids; both are needed to resolve conflicts for either shape.
    def initialize(lesson:, starts_at:, ends_at:, teacher_profile:, enrollment_ids:, student_profile_ids: [])
      @lesson = lesson
      @starts_at = starts_at
      @ends_at = ends_at
      @teacher_profile = teacher_profile
      @enrollment_ids = Array(enrollment_ids).compact
      @student_profile_ids = Array(student_profile_ids).compact
    end
    # rubocop:enable Metrics/ParameterLists

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

    # Resolves both participation shapes to a common set of student ids, so an enrollment-backed
    # student and a direct (enrollment-less) student are protected from double-booking alike.
    def target_student_ids
      @target_student_ids ||= (Enrollment.where(id: @enrollment_ids).distinct.pluck(:student_profile_id) +
                                @student_profile_ids).uniq
    end

    def student_participant_lessons
      ScheduledLessonEnrollment.where(student_profile_id: target_student_ids)
                               .or(ScheduledLessonEnrollment.where(
                                     enrollment_id: Enrollment.where(student_profile_id: target_student_ids)
                                   )).select(:scheduled_lesson_id)
    end

    def student_conflicts
      return [] if target_student_ids.empty?

      overlap(ScheduledLesson.where(id: student_participant_lessons)).distinct.to_a
    end
  end
end
