module OperationalReports
  DatasetResult = Data.define(:title, :headers, :rows)

  class Dataset
    TYPES = %w[teacher_workload teacher_attendance student_attendance lesson_completion lesson_reports
               payroll_summary programs course_offerings enrollments].freeze

    def initialize(type:, params: {})
      @type = type.to_s
      @params = params
    end

    def call
      raise ArgumentError, "unknown report" unless @type.in?(TYPES)

      method(@type).call
    end

    private

    def teacher_workload
      scope = lesson_scope.where(status: "completed").group("teacher_profiles.id", "teacher_profiles.display_name")
      rows = scope.pluck("teacher_profiles.display_name", Arel.sql("COUNT(scheduled_lessons.id)"),
                         Arel.sql("ROUND(SUM(EXTRACT(EPOCH FROM (ends_at - starts_at))) / 3600, 2)"))
      result(%w[teacher lessons hours], rows)
    end

    def teacher_attendance
      rows = lesson_scope.where.not(teacher_attendance_status: "not_checked_in")
                         .pluck("teacher_profiles.display_name", :starts_at, :teacher_checked_in_at,
                                :teacher_attendance_status)
      result(%w[teacher scheduled_at checked_in_at status], rows)
    end

    def student_attendance
      scope = LessonAttendance.joins(scheduled_lesson_enrollment: { enrollment: { student_profile: :user } },
                                     scheduled_lesson: :teacher_profile)
                              .where(scheduled_lessons: { starts_at: date_range })
      if @params[:teacher_id].present?
        scope = scope.where(scheduled_lessons: { teacher_profile_id: @params[:teacher_id] })
      end
      rows = scope.pluck(Arel.sql("users.first_name || ' ' || users.last_name"), "scheduled_lessons.starts_at",
                         :status, :minutes_late)
      result(%w[student lesson_at status minutes_late], rows)
    end

    def lesson_completion
      rows = lesson_scope.pluck("scheduled_lessons.public_id", "teacher_profiles.display_name", :starts_at, :status)
      result(%w[lesson teacher starts_at status], rows)
    end

    def lesson_reports
      scope = LessonReport.joins(scheduled_lesson: :teacher_profile)
                          .where(scheduled_lessons: { starts_at: date_range })
      rows = scope.pluck(:public_id, "teacher_profiles.display_name", :status, :submitted_at, :reviewed_at)
      result(%w[report teacher status submitted_at reviewed_at], rows)
    end

    def payroll_summary
      scope = TeacherPayroll.joins(:teacher_profile).where(period_starts_on: date_range)
      rows = scope.pluck(:public_id, "teacher_profiles.display_name", :period_starts_on, :period_ends_on,
                         :status, :currency, :net_amount)
      result(%w[payroll teacher period_start period_end status currency net_amount], rows)
    end

    def programs
      count = Arel.sql("COUNT(course_offerings.id)")
      rows = Program.left_joins(:course_offerings).group(:id).pluck(:name_en, :status, count)
      result(%w[program status offerings], rows)
    end

    def course_offerings
      rows = CourseOffering.joins(:program).pluck("programs.name_en", "course_offerings.title_en",
                                                  "course_offerings.status", :planned_start_on, :planned_end_on)
      result(%w[program offering status planned_start planned_end], rows)
    end

    def enrollments
      rows = Enrollment.joins(student_profile: :user, course_offering: :program)
                       .pluck(Arel.sql("users.first_name || ' ' || users.last_name"), "programs.name_en",
                              "course_offerings.title_en", "enrollments.status", "enrollments.applied_on")
      result(%w[student program offering status applied_on], rows)
    end

    def lesson_scope
      scope = ScheduledLesson.joins(:teacher_profile, :course_offering).where(starts_at: date_range)
      scope = filter_lesson_ownership(scope)
      filter_lesson_status(scope)
    end

    def filter_lesson_ownership(scope)
      scope = scope.where(teacher_profile_id: @params[:teacher_id]) if @params[:teacher_id].present?
      scope = scope.where(course_offering_id: @params[:course_id]) if @params[:course_id].present?
      scope = scope.where(course_offerings: { program_id: @params[:program_id] }) if @params[:program_id].present?
      scope
    end

    def filter_lesson_status(scope)
      return scope unless ScheduledLesson::STATUSES.include?(@params[:status])

      scope.where(status: @params[:status])
    end

    def date_range
      from = parse_date(@params[:from]) || Date.current.beginning_of_month
      to = parse_date(@params[:to]) || Date.current.end_of_month
      from.beginning_of_day..to.end_of_day
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def result(headers, rows) = DatasetResult.new(@type, headers, rows)
  end
end
