module Admin
  class StudentsController < BaseController
    before_action :set_profile, except: %i[index new create]

    ONBOARDING_KEYS = %i[
      first_name last_name email display_name date_of_birth gender student_type learning_status
      nationality country_of_residence city phone_number whatsapp_number preferred_contact_method
      preferred_interface_locale preferred_learning_language native_language current_quran_level
      reading_level tajweed_level memorization_level wallet_balance discount_percentage
      assigned_teacher_profile_id course_offering_id package_name learning_goals sessions_per_month
      lesson_duration_minutes weekly_lesson_count session_type trial_lesson_at weekly_price
      billing_currency account_delivery_method existing_guardian_id guardian_name guardian_email
      guardian_phone sibling_student_profile_id
      schedule_weekday_1 schedule_time_1 schedule_weekday_2 schedule_time_2
      schedule_weekday_3 schedule_time_3
    ].freeze

    UPDATE_KEYS = %i[
      display_name gender date_of_birth nationality country_of_residence city phone_number
      whatsapp_number preferred_contact_method preferred_interface_locale preferred_learning_language
      native_language current_quran_level reading_level tajweed_level memorization_level
      memorized_surahs memorized_juz_count learning_goals learning_notes special_learning_needs
      medical_notes safeguarding_notes emergency_contact_name emergency_contact_phone student_type
      learning_status joined_on left_on internal_notes
    ].freeze

    def index
      @pagy, @profiles = pagy(:offset, Admin::StudentsQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @profile.events.includes(:actor).recent_first.limit(20)
      @guardianships = @profile.student_guardianships.includes(:guardian).recent_first
    end

    def new
      @profile = StudentProfile.new
      load_onboarding_collections
    end

    def edit; end

    def create
      @profile = Admin::Onboarding::CreateStudent.new(actor: current_user, attributes: onboarding_params).call
      if @profile.persisted? && @profile.errors.empty?
        redirect_to admin_student_path(@profile), notice: t("students.messages.created"), status: :see_other
      else
        load_onboarding_collections
        render :new, status: :unprocessable_content
      end
    end

    def update
      @profile = Admin::StudentProfiles::Update.new(actor: current_user, profile: @profile, attributes: update_params).call
      respond_to_save("updated", :edit)
    end

    %i[verify archive restore].each do |action|
      define_method(action) do
        @profile = Admin::StudentProfiles::Transition.new(actor: current_user, profile: @profile, action:).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_profile
      @profile = StudentProfile.includes(:user).find(params.expect(:id))
    end

    def load_onboarding_collections
      @teacher_profiles = TeacherProfile.where.not(profile_status: "archived").order(:display_name)
      @course_offerings = CourseOffering.where(status: "open").order(:title_ar)
      @guardians = Guardian.where.not(status: "archived").order(:full_name)
      @student_profiles = StudentProfile.where.not(profile_status: "archived").order(:display_name)
    end

    def onboarding_params
      params.expect(student_profile: ONBOARDING_KEYS).to_h
    end

    def update_params
      params.expect(student_profile: UPDATE_KEYS).to_h
    end

    def respond_to_save(message, template)
      if @profile.errors.empty?
        redirect_to admin_student_path(@profile), notice: t("students.messages.#{message}"), status: :see_other
      else
        if template == :show
          @events = @profile.events.includes(:actor).recent_first.limit(20)
          @guardianships = @profile.student_guardianships.includes(:guardian).recent_first
        end
        render template, status: :unprocessable_content
      end
    end
  end
end
