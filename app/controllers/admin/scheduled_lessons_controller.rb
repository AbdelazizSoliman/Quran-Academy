module Admin
  class ScheduledLessonsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show attendance]
    before_action :set_lesson, except: %i[index new create]

    def index
      @week_start = selected_week.beginning_of_week(:sunday)
      @week_end = @week_start + 6.days
      query_params = params.to_unsafe_h.merge(from: @week_start.iso8601, to: @week_end.iso8601)
      @lessons = ScheduledLessonsQuery.new(params: query_params).call.to_a
      @lessons_by_day = @lessons.group_by { |lesson| lesson.starts_at.in_time_zone(academy_time_zone).to_date }
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
      @offerings = CourseOffering.where(status: %w[draft open in_progress]).order(:title_en)
    end

    def show
      load_show_data
    end

    def new
      @lesson = ScheduledLesson.new(academy_time_zone: AcademySetting.current_or_nil&.default_time_zone || "Cairo")
      load_options
      load_students
    end

    def edit
      load_options
    end

    def create
      attributes = lesson_params
      @lesson = if attributes[:lesson_type] == "direct_student"
                  ScheduledLessons::CreateDirect.new(actor: current_user, attributes:).call
                else
                  ScheduledLessons::Create.new(
                    actor: current_user, attributes: attributes.except(:lesson_type, :student_profile_id)
                  ).call
                end
      load_students
      respond_to_save(:created, :new)
    end

    def update
      @lesson = ScheduledLessons::Update.new(actor: current_user, lesson: @lesson, attributes: lesson_params).call
      respond_to_save(:updated, :edit)
    end

    %i[schedule].each do |action|
      define_method(action) do
        @lesson = ScheduledLessons::Transition.new(actor: current_user, lesson: @lesson, action:).call
        respond_to_save(action, :show)
      end
    end

    def check_in_teacher
      operate LessonOperations::CheckIn.new(actor: current_user, lesson: @lesson, override: true,
                                            reason: params[:reason])
    end

    def start
      operate LessonOperations::Start.new(actor: current_user, lesson: @lesson, override: true,
                                          reason: params[:reason])
    end

    def complete
      options = { override: true, reason: params[:reason], mark_unresolved_absent: params[:mark_unresolved_absent],
                  notes: params[:completion_notes] }
      operate LessonOperations::Complete.new(actor: current_user, lesson: @lesson, options:)
    end

    def lock_attendance
      operate LessonOperations::LockAttendance.new(actor: current_user, lesson: @lesson)
    end

    def reopen_attendance
      operate LessonOperations::ReopenAttendance.new(actor: current_user, lesson: @lesson, reason: params[:reason])
    end

    def attendance
      @attendances = @lesson.lesson_attendances.includes(
        :events, scheduled_lesson_enrollment: [:student_profile, { enrollment: :student_profile }]
      )
      @events = @lesson.events.includes(:actor).recent_first.limit(50)
      render "admin/lesson_attendances/show"
    end

    def cancel
      @lesson = ScheduledLessons::Transition.new(actor: current_user, lesson: @lesson, action: :cancel,
                                                 cancellation_reason: params[:cancellation_reason]).call
      respond_to_save(:cancelled, :show)
    end

    def reschedule
      load_options
    end

    def apply_reschedule
      @lesson = ScheduledLessons::Reschedule.new(actor: current_user, lesson: @lesson,
                                                 starts_at: params[:starts_at], ends_at: params[:ends_at]).call
      respond_to_save(:rescheduled, :show)
    end

    def archive
      @lesson = ScheduledLessons::Transition.new(actor: current_user, lesson: @lesson, action: :archive).call
      respond_to_save(:archived, :show)
    end

    private

    def selected_week
      Date.iso8601(params[:week].to_s)
    rescue Date::Error
      Date.current
    end

    def academy_time_zone
      @academy_time_zone ||= AcademySetting.current_or_nil&.default_time_zone || "Cairo"
    end

    def load_show_data
      @events = @lesson.events.includes(:actor).recent_first.limit(30)
      @participants = @lesson.scheduled_lesson_enrollments.includes(:student_profile,
                                                                    enrollment: { student_profile: :user })
      participant_ids = @participants.map(&:enrollment_id)
      @available_enrollments = if @lesson.course_offering
                                 @lesson.course_offering.enrollments.where(status: %w[approved active paused])
                                        .where.not(id: participant_ids).includes(:student_profile).order(:id)
                               else
                                 Enrollment.none
                               end
    end

    def set_lesson
      @lesson = ScheduledLesson.includes(:course_offering, :teacher_profile).find(params.expect(:id))
    end

    def load_options
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
      @offerings = CourseOffering.where(status: %w[draft open in_progress]).order(:title_en)
    end

    def load_students
      @students = StudentProfile.where.not(profile_status: "archived").order(:display_name)
    end

    def lesson_params
      permitted = %i[course_offering_id teacher_profile_id title_ar title_en starts_at ends_at academy_time_zone
                     delivery_mode location_name online_meeting_url scheduling_source lesson_type
                     student_profile_id]
      params.expect(scheduled_lesson: permitted)
    end

    def respond_to_save(message, template)
      if @lesson.persisted? && @lesson.errors.empty?
        redirect_to admin_scheduled_lesson_path(@lesson), notice: t("scheduling.messages.#{message}"),
                                                          status: :see_other
      else
        template == :show ? load_show_data : load_options
        render template, status: :unprocessable_content
      end
    end

    def operate(operation)
      @lesson = operation.call
      if @lesson.errors.empty?
        redirect_to attendance_admin_scheduled_lesson_path(@lesson), notice: t("attendance.messages.updated"),
                                                                     status: :see_other
      else
        redirect_to admin_scheduled_lesson_path(@lesson), alert: @lesson.errors.full_messages.to_sentence,
                                                          status: :see_other
      end
    end
  end
end
