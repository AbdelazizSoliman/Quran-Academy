module Admin
  class EnrollmentLessonSchedulesController < BaseController
    before_action :set_enrollment
    before_action :set_schedule, only: %i[show new_change apply_change cancel]

    def index
      @schedules = @enrollment.lesson_schedules.includes(:teacher_profile, :slots).order(starts_on: :desc)
    end

    def show
      @events = @schedule.events.includes(:actor).recent_first.limit(50)
      @issues = @schedule.generation_issues.unresolved.order(:recurrence_date)
      @lessons = recurring_lessons.where(starts_at: Time.current..).chronological.limit(50)
    end

    def new
      @schedule = @enrollment.lesson_schedules.new(default_attributes)
      load_options
    end

    def create
      @schedule = EnrollmentLessonSchedules::Create.new(
        actor: current_user, enrollment: @enrollment, attributes: schedule_params, slots: parsed_slots
      ).call
      respond_to_save
    end

    def new_change
      @replacement = @enrollment.lesson_schedules.new(
        teacher_profile: @schedule.teacher_profile, lesson_duration_minutes: @schedule.lesson_duration_minutes,
        time_zone: @schedule.time_zone, starts_on: Date.current + 1.day
      )
      load_options
    end

    def apply_change
      @replacement = EnrollmentLessonSchedules::Change.new(
        actor: current_user, schedule: @schedule, effective_on: Date.parse(params.expect(:effective_on)),
        attributes: schedule_params, slots: parsed_slots
      ).call
      if @replacement.is_a?(EnrollmentLessonSchedule) && @replacement != @schedule && @replacement.persisted?
        redirect_to admin_enrollment_lesson_schedule_path(@enrollment, @replacement), status: :see_other,
                                                                                      notice: schedule_message(:changed)
      else
        @replacement = @enrollment.lesson_schedules.new(schedule_params)
        load_options
        render :new_change, status: :unprocessable_content
      end
    rescue Date::Error
      @schedule.errors.add(:starts_on, :invalid)
      @replacement = @enrollment.lesson_schedules.new(schedule_params)
      load_options
      render :new_change, status: :unprocessable_content
    end

    def cancel
      EnrollmentLessonSchedules::Cancel.new(actor: current_user, schedule: @schedule).call
      redirect_to admin_enrollment_lesson_schedule_path(@enrollment, @schedule), status: :see_other,
                                                                                 notice: schedule_message(:cancelled)
    end

    private

    def set_enrollment
      @enrollment = Enrollment.includes(:student_profile, :course_offering).find(params.expect(:enrollment_id))
    end

    def set_schedule
      @schedule = @enrollment.lesson_schedules.find(params.expect(:id))
    end

    def load_options
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
    end

    def schedule_params
      params.expect(enrollment_lesson_schedule: %i[teacher_profile_id starts_on ends_on
                                                   lesson_duration_minutes time_zone status])
    end

    def parsed_slots
      params.dig(:enrollment_lesson_schedule, :slots_text).to_s.lines.filter_map do |line|
        weekday, time = line.strip.split(/\s+/, 2)
        next if weekday.blank? && time.blank?

        { weekday: weekday&.downcase, starts_at_local: time }
      end
    end

    def default_attributes
      {
        teacher_profile: @enrollment.student_profile.assigned_teacher_profile,
        starts_on: @enrollment.course_offering.planned_start_on || Date.current,
        ends_on: @enrollment.course_offering.planned_end_on,
        lesson_duration_minutes: @enrollment.student_profile.lesson_duration_minutes ||
          @enrollment.course_offering.default_lesson_duration_minutes,
        time_zone: @enrollment.student_profile.user.time_zone, status: "active"
      }
    end

    def recurring_lessons
      ScheduledLesson.joins(:enrollment_lesson_schedule_slot)
                     .where(enrollment_lesson_schedule_slots: { enrollment_lesson_schedule_id: @schedule.id })
    end

    def respond_to_save
      if @schedule.persisted? && @schedule.errors.empty?
        redirect_to admin_enrollment_lesson_schedule_path(@enrollment, @schedule), status: :see_other,
                                                                                   notice: schedule_message(:created)
      else
        load_options
        render :new, status: :unprocessable_content
      end
    end

    def schedule_message(key) = t("recurring_schedules.messages.#{key}")
  end
end
