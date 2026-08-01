module Teacher
  class AvailabilityExceptionsController < ApplicationController
    before_action :require_teacher!
    before_action :set_exception, only: %i[edit update]

    def index
      profile = current_user.teacher_profile
      @exceptions = profile ? profile.availability_exceptions.visible.recent_first : TeacherAvailabilityException.none
    end

    def new
      @exception = TeacherAvailabilityException.new
    end

    def edit; end

    def create
      @exception = TeacherAvailabilityExceptions::Create.new(
        actor: current_user, teacher_profile: current_user.teacher_profile, attributes: exception_params
      ).call
      respond_to_save(:created, :new)
    end

    def update
      @exception = TeacherAvailabilityExceptions::Update.new(actor: current_user, exception: @exception,
                                                             attributes: exception_params).call
      respond_to_save(:updated, :edit)
    end

    private

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end

    def set_exception
      @exception = current_user.teacher_profile.availability_exceptions.find(params.expect(:id))
    end

    def exception_params
      params.expect(teacher_availability_exception: %i[exception_date starts_at_local ends_at_local time_zone
                                                       exception_type reason])
    end

    def respond_to_save(message, template)
      if @exception.persisted? && @exception.errors.empty?
        redirect_to teacher_availability_exceptions_path, notice: t("scheduling.messages.#{message}"),
                                                          status: :see_other
      else
        render template, status: :unprocessable_content
      end
    end
  end
end
