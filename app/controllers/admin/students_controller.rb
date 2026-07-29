module Admin
  class StudentsController < BaseController
    before_action :set_profile, except: %i[index new create]

    def index
      @pagy, @profiles = pagy(:offset, StudentsQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @profile.events.includes(:actor).recent_first.limit(20)
      @guardianships = @profile.student_guardianships.includes(:guardian).recent_first
    end

    def new
      @eligible_student_users = eligible_student_users
      @user = eligible_student_users.find_by(id: params[:user_id])
      @profile = @user ? @user.build_student_profile : StudentProfile.new
    end

    def edit; end

    def create
      @eligible_student_users = eligible_student_users
      @user = eligible_student_users.find_by(id: params.dig(:student_profile, :user_id))
      @profile = if @user
                   StudentProfiles::Create.new(actor: current_user, user: @user,
                                               attributes: profile_params).call
                 else
                   StudentProfile.new
                 end
      @profile.errors.add(:user, :must_be_available) unless @user
      respond_to_save("created", :new)
    end

    def update
      @profile = StudentProfiles::Update.new(actor: current_user, profile: @profile, attributes: profile_params).call
      respond_to_save("updated", :edit)
    end

    %i[verify archive restore].each do |action|
      define_method(action) do
        @profile = StudentProfiles::Transition.new(actor: current_user, profile: @profile, action:).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_profile
      @profile = StudentProfile.includes(:user).find(params.expect(:id))
    end

    def eligible_student_users
      User.student.where.not(id: StudentProfile.select(:user_id)).order(:first_name, :last_name)
    end

    def profile_params
      params.expect(student_profile: %i[
                      display_name gender date_of_birth nationality country_of_residence
                      city phone_number whatsapp_number preferred_contact_method
                      preferred_interface_locale preferred_learning_language native_language
                      current_quran_level reading_level tajweed_level memorization_level
                      memorized_surahs memorized_juz_count learning_goals learning_notes
                      special_learning_needs medical_notes safeguarding_notes
                      emergency_contact_name emergency_contact_phone student_type
                      learning_status joined_on left_on internal_notes
                    ])
    end

    def respond_to_save(message, template)
      if @profile.persisted? && @profile.errors.empty?
        redirect_to admin_student_path(@profile), notice: t("students.messages.#{message}"), status: :see_other
      else
        @events = @profile.events.includes(:actor).recent_first.limit(20) if template == :show
        @guardianships = @profile.student_guardianships.includes(:guardian).recent_first if template == :show
        render template, status: :unprocessable_content
      end
    end
  end
end
