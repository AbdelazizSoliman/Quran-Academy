module Dashboard
  class GuardianPortal
    ATTENDED = %w[present late left_early].freeze

    def initialize(user:, child_id: nil, now: Time.current)
      @guardian = user.guardian_profile
      @child_id = child_id
      @now = now
    end

    def call
      children = guardian_children.includes(:user, :student_progress, :assigned_teacher_profile).to_a
      selected_child = children.find { |child| child.id.to_s == @child_id.to_s } || children.first
      return empty_result(children) unless selected_child

      lessons = selected_child.scheduled_lessons
      {
        guardian: @guardian,
        children:,
        selected_child:,
        today_lessons: lessons.where(starts_at: @now.in_time_zone.all_day)
                              .where(status: ScheduledLesson::OPERATIONAL_STATUSES + ["completed"])
                              .chronological.includes(:course_offering, :teacher_profile).to_a,
        upcoming_lessons: lessons.operational.where(starts_at: @now..30.days.from_now)
                                 .chronological.limit(5).includes(:course_offering, :teacher_profile).to_a,
        attendance: attendance_summary(selected_child),
        progress: selected_child.student_progress,
        reports_count: visible_reports(selected_child).count
      }
    end

    private

    def guardian_children
      return StudentProfile.none unless @guardian

      StudentProfile.joins(:student_guardianships)
                    .where(student_guardianships: { guardian_id: @guardian.id, status: "active" }).distinct
    end

    def attendance_summary(child)
      scope = LessonAttendance.joins(scheduled_lesson_enrollment: :enrollment)
                              .where(enrollments: { student_profile_id: child.id })
      total = scope.where(status: LessonAttendance::FINAL_STATUSES).count
      attended = scope.where(status: ATTENDED).count
      { total:, attended:, rate: total.zero? ? 0 : ((attended.to_f / total) * 100).round }
    end

    def visible_reports(child)
      LessonStudentReport.student_visible.joins(:scheduled_lesson_enrollment, :lesson_report)
                         .where(lesson_reports: { status: %w[reviewed locked] },
                                scheduled_lesson_enrollments: { enrollment_id: child.enrollment_ids })
    end

    def empty_result(children)
      { guardian: @guardian, children:, selected_child: nil, today_lessons: [], upcoming_lessons: [],
        attendance: { total: 0, attended: 0, rate: 0 }, progress: nil, reports_count: 0 }
    end
  end
end
