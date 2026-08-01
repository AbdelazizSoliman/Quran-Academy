module Teacher
  class AvailabilitiesController < ApplicationController
    before_action :require_teacher!
    before_action :set_availability, only: %i[edit update]

    def index
      profile = current_user.teacher_profile
      @availabilities = profile ? profile.availabilities.visible.chronological : TeacherAvailability.none
    end

    def new
      @availability = TeacherAvailability.new
    end

    def edit; end

    def create
      @availability = TeacherAvailabilities::Create.new(
        actor: current_user, teacher_profile: current_user.teacher_profile, attributes: teacher_params
      ).call
      respond_to_save(:created, :new)
    end

    def update
      @availability = TeacherAvailabilities::Update.new(actor: current_user, availability: @availability,
                                                        attributes: teacher_params).call
      respond_to_save(:updated, :edit)
    end

    private

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end

    def set_availability
      @availability = current_user.teacher_profile.availabilities.find(params.expect(:id))
    end

    def teacher_params
      params.expect(teacher_availability: %i[weekday starts_at_local ends_at_local time_zone effective_from
                                             effective_until availability_type notes])
    end

    def respond_to_save(message, template)
      if @availability.persisted? && @availability.errors.empty?
        redirect_to teacher_availabilities_path, notice: t("scheduling.messages.#{message}"), status: :see_other
      else
        render template, status: :unprocessable_content
      end
    end
  end
end
