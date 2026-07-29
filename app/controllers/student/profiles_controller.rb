module Student
  class ProfilesController < BaseController
    before_action :set_profile

    def show
      render :missing unless @profile
    end

    def edit
      render :missing unless @profile
    end

    def update
      unless @profile
        render :missing, status: :not_found
        return
      end
      @profile = Profiles::Update.new(actor: current_user, profile: @profile, attributes: profile_params).call
      if @profile.errors.empty?
        redirect_to student_profile_path, notice: t("student.profile.messages.updated"), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_profile
      @profile = current_user.student_profile
    end

    def profile_params
      params.expect(student_profile: %i[
                      display_name phone_number whatsapp_number country_of_residence city
                      preferred_learning_language native_language learning_goals
                    ])
    end
  end
end
