module StudentLearningProfiles
  class Access
    CURRENT_ENROLLMENT_STATUSES = %w[approved active paused].freeze

    def initialize(actor)
      @actor = actor
    end

    def student_scope
      return StudentProfile.all if administrator?
      return StudentProfile.none unless teacher?

      StudentProfile.where(assigned_teacher_profile_id: teacher_profile.id)
                    .or(StudentProfile.where(id: enrolled_student_ids))
                    .or(StudentProfile.where(id: operational_lesson_student_ids))
                    .distinct
    end

    def profile_scope
      StudentLearningProfile.where(student_profile_id: student_scope.select(:id))
    end

    def can_read?(student_profile) = active_staff? && student_scope.exists?(id: student_profile.id)
    def can_write?(student_profile) = can_read?(student_profile)
    def can_manage_highly_sensitive? = administrator?

    private

    attr_reader :actor

    def active_staff? = actor&.active? && (actor.admin? || actor.teacher?)
    def administrator? = actor&.active? && actor.admin?
    def teacher? = actor&.active? && actor.teacher? && teacher_profile.present?
    def teacher_profile = actor.teacher_profile

    def enrolled_student_ids
      Enrollment.joins(course_offering: :course_offering_teachers)
                .where(status: CURRENT_ENROLLMENT_STATUSES,
                       course_offering_teachers: { teacher_profile_id: teacher_profile.id })
                .select(:student_profile_id)
    end

    def operational_lesson_student_ids
      participants = ScheduledLessonEnrollment.joins(:scheduled_lesson)
                                              .where(participation_status: "expected",
                                                     scheduled_lessons: {
                                                       teacher_profile_id: teacher_profile.id,
                                                       status: ScheduledLesson::OPERATIONAL_STATUSES
                                                     })
      direct_ids = participants.where.not(student_profile_id: nil).select(:student_profile_id)
      enrollment_ids = participants.where.not(enrollment_id: nil).select(:enrollment_id)
      enrollment_student_ids = Enrollment.where(id: enrollment_ids).select(:student_profile_id)
      StudentProfile.where(id: direct_ids).or(StudentProfile.where(id: enrollment_student_ids)).select(:id)
    end
  end
end
