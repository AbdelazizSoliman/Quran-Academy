module Admin
  class TeacherAvailabilitiesController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_availability, except: %i[index new create]

    def index
      @availabilities = TeacherAvailability.includes(:teacher_profile).order(:weekday, :starts_at_local)
    end

    def show
      @events = @availability.events.includes(:actor).recent_first.limit(30)
    end

    def new
      @availability = TeacherAvailability.new(teacher_profile_id: params[:teacher_profile_id])
      load_options
    end

    def edit
      load_options
    end

    def create
      attributes = availability_params
      teacher = TeacherProfile.find(attributes.fetch(:teacher_profile_id))
      @availability = TeacherAvailabilities::Create.new(actor: current_user, teacher_profile: teacher,
                                                        attributes:).call
      respond_to_save(:created, :new)
    end

    def update
      @availability = TeacherAvailabilities::Update.new(actor: current_user, availability: @availability,
                                                        attributes: availability_params).call
      respond_to_save(:updated, :edit)
    end

    %i[activate deactivate archive].each do |action|
      define_method(action) do
        @availability = TeacherAvailabilities::Transition.new(actor: current_user, availability: @availability,
                                                              action:).call
        respond_to_save(action, :show)
      end
    end

    private

    def set_availability
      @availability = TeacherAvailability.find(params.expect(:id))
    end

    def load_options
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
    end

    def availability_params
      params.expect(teacher_availability: %i[teacher_profile_id weekday starts_at_local ends_at_local time_zone
                                             effective_from effective_until availability_type notes])
    end

    def respond_to_save(message, template)
      if @availability.persisted? && @availability.errors.empty?
        redirect_to admin_teacher_availability_path(@availability), notice: t("scheduling.messages.#{message}"),
                                                                    status: :see_other
      else
        load_options
        render template, status: :unprocessable_content
      end
    end
  end
end
