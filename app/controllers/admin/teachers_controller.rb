module Admin
  class TeachersController < BaseController
    before_action :set_profile, except: %i[index new create]

    def index
      @pagy, @profiles = pagy(:offset, TeachersQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @profile.events.includes(:actor).recent_first.limit(20)
    end

    def new
      @eligible_teacher_users = eligible_teacher_users
      @user = eligible_teacher_users.find_by(id: params[:user_id])
      @profile = @user ? @user.build_teacher_profile : TeacherProfile.new
    end

    def edit; end

    def create
      @eligible_teacher_users = eligible_teacher_users
      @user = eligible_teacher_users.find_by(id: params.dig(:teacher_profile, :user_id))
      @profile = @user ? create_profile : TeacherProfile.new
      @profile.errors.add(:user, :must_be_available) unless @user
      if @profile.persisted?
        redirect_to admin_teacher_path(@profile), notice: t("teachers.messages.created"), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @profile = TeacherProfiles::Update.new(
        actor: current_user, profile: @profile, attributes: profile_params
      ).call
      respond_to_save("updated")
    end

    %i[verify archive restore].each do |action|
      define_method(action) do
        @profile = TeacherProfiles::Transition.new(actor: current_user, profile: @profile, action:).call
        respond_to_save(action.to_s)
      end
    end

    private

    def set_profile
      @profile = TeacherProfile.includes(:user).find(params.expect(:id))
    end

    def eligible_teacher_users
      User.teacher.where.not(id: TeacherProfile.select(:user_id)).order(:first_name, :last_name)
    end

    def create_profile
      TeacherProfiles::Create.new(actor: current_user, user: @user, attributes: profile_params).call
    end

    def profile_params
      params.expect(teacher_profile: [
                      :display_name, :bio, :gender, :date_of_birth, :nationality,
                      :country_of_residence, :city, :phone_number, :whatsapp_number,
                      :emergency_contact_name, :emergency_contact_phone, :highest_qualification,
                      :qualification_details, :years_of_teaching_experience,
                      :quran_teaching_experience_years, :tajweed_qualification, :ijazah_status,
                      :ijazah_details, :employment_status, :engagement_type, :joined_on, :left_on,
                      :default_lesson_rate, :compensation_currency, :compensation_unit, :internal_notes,
                      { teaching_languages: [], student_age_groups: [], teaching_specializations: [] }
                    ])
    end

    def respond_to_save(message)
      if @profile.errors.empty?
        redirect_to admin_teacher_path(@profile), notice: t("teachers.messages.#{message}"), status: :see_other
      else
        template = action_name == "update" ? :edit : :show
        @events = @profile.events.includes(:actor).recent_first.limit(20) if template == :show
        render template, status: :unprocessable_content
      end
    end
  end
end
