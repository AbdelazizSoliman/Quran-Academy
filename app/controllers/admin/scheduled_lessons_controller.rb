module Admin
  class ScheduledLessonsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_lesson, except: %i[index new create]

    def index
      @pagy, @lessons = pagy(:offset, ScheduledLessonsQuery.new(params:).call, limit: 20)
    end

    def show
      @events = @lesson.events.includes(:actor).recent_first.limit(30)
      @participants = @lesson.scheduled_lesson_enrollments.includes(enrollment: { student_profile: :user })
      participant_ids = @participants.map(&:enrollment_id)
      @available_enrollments = @lesson.course_offering.enrollments.where(status: %w[approved active paused])
                                      .where.not(id: participant_ids).includes(:student_profile).order(:id)
    end

    def new
      @lesson = ScheduledLesson.new(academy_time_zone: AcademySetting.current_or_nil&.default_time_zone || "Cairo")
      load_options
    end

    def edit
      load_options
    end

    def create
      @lesson = ScheduledLessons::Create.new(actor: current_user, attributes: lesson_params).call
      respond_to_save(:created, :new)
    end

    def update
      @lesson = ScheduledLessons::Update.new(actor: current_user, lesson: @lesson, attributes: lesson_params).call
      respond_to_save(:updated, :edit)
    end

    %i[schedule start complete].each do |action|
      define_method(action) do
        @lesson = ScheduledLessons::Transition.new(actor: current_user, lesson: @lesson, action:).call
        respond_to_save(action, :show)
      end
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

    def set_lesson
      @lesson = ScheduledLesson.includes(:course_offering, :teacher_profile).find(params.expect(:id))
    end

    def load_options
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
      @offerings = CourseOffering.where(status: %w[draft open in_progress]).order(:title_en)
    end

    def lesson_params
      permitted = %i[course_offering_id teacher_profile_id title_ar title_en starts_at ends_at academy_time_zone
                     delivery_mode location_name online_meeting_url scheduling_source]
      params.expect(scheduled_lesson: permitted)
    end

    def respond_to_save(message, template)
      if @lesson.persisted? && @lesson.errors.empty?
        redirect_to admin_scheduled_lesson_path(@lesson), notice: t("scheduling.messages.#{message}"),
                                                          status: :see_other
      else
        load_options
        render template, status: :unprocessable_content
      end
    end
  end
end
