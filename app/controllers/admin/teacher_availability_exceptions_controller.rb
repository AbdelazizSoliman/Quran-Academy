module Admin
  class TeacherAvailabilityExceptionsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_exception, except: %i[index new create]

    def index
      @exceptions = TeacherAvailabilityException.includes(:teacher_profile).order(exception_date: :desc)
    end

    def show
      @events = @exception.events.includes(:actor).recent_first.limit(30)
    end

    def new
      @exception = TeacherAvailabilityException.new(teacher_profile_id: params[:teacher_profile_id])
      load_options
    end

    def edit
      load_options
    end

    def create
      teacher = TeacherProfile.find(params.expect(teacher_availability_exception: :teacher_profile_id))
      @exception = TeacherAvailabilityExceptions::Create.new(actor: current_user, teacher_profile: teacher,
                                                             attributes: exception_params).call
      respond_to_save(:created, :new)
    end

    def update
      @exception = TeacherAvailabilityExceptions::Update.new(actor: current_user, exception: @exception,
                                                             attributes: exception_params).call
      respond_to_save(:updated, :edit)
    end

    %i[cancel archive].each do |action|
      define_method(action) do
        @exception = TeacherAvailabilityExceptions::Transition.new(actor: current_user, exception: @exception,
                                                                   action:).call
        respond_to_save(action, :show)
      end
    end

    private

    def set_exception
      @exception = TeacherAvailabilityException.find(params.expect(:id))
    end

    def load_options
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
    end

    def exception_params
      params.expect(teacher_availability_exception: %i[teacher_profile_id exception_date starts_at_local ends_at_local
                                                       time_zone exception_type reason])
    end

    def respond_to_save(message, template)
      if @exception.persisted? && @exception.errors.empty?
        redirect_to admin_teacher_availability_exception_path(@exception), notice: t("scheduling.messages.#{message}"),
                                                                           status: :see_other
      else
        load_options
        render template, status: :unprocessable_content
      end
    end
  end
end
