module Teacher
  class ProfilesController < BaseController
    before_action :set_profile

    def show; end

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
        redirect_to teacher_profile_path, notice: t("teacher.profile.messages.updated"), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_profile
      @profile = current_user.teacher_profile
    end

    def profile_params
      params.expect(teacher_profile: [
                      :display_name, :bio, :gender, :date_of_birth, :nationality,
                      :country_of_residence, :city, :phone_number, :whatsapp_number,
                      :emergency_contact_name, :emergency_contact_phone, :highest_qualification,
                      :qualification_details, :years_of_teaching_experience,
                      :quran_teaching_experience_years, :tajweed_qualification, :ijazah_status,
                      :ijazah_details,
                      { teaching_languages: [], student_age_groups: [], teaching_specializations: [] }
                    ])
    end
  end
end
