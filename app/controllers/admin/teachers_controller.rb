module Admin
  class TeachersController < BaseController
    before_action :set_profile, except: %i[index import import_create export new create]

    ONBOARDING_KEYS = [
      :first_name, :last_name, :email, :display_name, :phone_number, :whatsapp_number, :online_meeting_url,
      :notification_method, :message_language, :employment_status, :workload_percentage, :on_leave,
      :work_start_time, :work_end_time, :compensation_unit, :default_lesson_rate, :monthly_salary,
      :compensation_currency, :mid_period_previous_dues, { work_days: [] }
    ].freeze

    UPDATE_KEYS = [
      :display_name, :bio, :gender, :date_of_birth, :nationality, :country_of_residence, :city,
      :phone_number, :whatsapp_number, :online_meeting_url, :emergency_contact_name, :emergency_contact_phone,
      :highest_qualification, :qualification_details, :years_of_teaching_experience,
      :quran_teaching_experience_years, :tajweed_qualification, :ijazah_status, :ijazah_details,
      :employment_status, :engagement_type, :joined_on, :left_on, :default_lesson_rate,
      :compensation_currency, :compensation_unit, :internal_notes,
      { teaching_languages: [], student_age_groups: [], teaching_specializations: [] }
    ].freeze

    def index
      @pagy, @profiles = pagy(:offset, Admin::TeachersQuery.new(params:).call, limit: 15)
      @teacher_metrics = Admin::TeacherMetrics.new(profiles: @profiles).call
    end

    def import; end

    def import_create
      upload = params[:file]
      unless upload.respond_to?(:tempfile)
        flash.now[:alert] = t("teachers.madarak.import_file_required")
        return render :import, status: :unprocessable_content
      end

      @result = Admin::TeachersCsvImport.new(actor: current_user, io: upload.tempfile).call
      if @result.errors.empty?
        redirect_to admin_teachers_path, notice: t("teachers.madarak.import_success", count: @result.created_count)
      else
        flash.now[:alert] = t("teachers.madarak.import_partial", count: @result.created_count,
                            errors: @result.errors.size)
        render :import, status: :unprocessable_content
      end
    rescue CSV::MalformedCSVError => e
      @import_error = e.message
      render :import, status: :unprocessable_content
    end

    def export
      profiles = Admin::TeachersQuery.new(params:).call
      metrics = Admin::TeacherMetrics.new(profiles:).call
      data = Admin::TeachersCsvExport.new(profiles, metrics:).call
      send_data "\uFEFF#{data}", filename: "quran-academy-teachers-#{Date.current}.csv",
                                type: "text/csv; charset=utf-8"
    end

    def show
      @events = @profile.events.includes(:actor).recent_first.limit(20)
      @availabilities = @profile.availabilities.visible.chronological
    end

    def new
      @profile = TeacherProfile.new
    end

    def edit; end

    def create
      @profile = Admin::Onboarding::CreateTeacher.new(actor: current_user, attributes: onboarding_params).call
      if @profile.persisted? && @profile.errors.empty?
        redirect_to admin_teacher_path(@profile), notice: t("teachers.messages.created"), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @profile = Admin::TeacherProfiles::Update.new(
        actor: current_user, profile: @profile, attributes: update_params
      ).call
      respond_to_save("updated")
    end

    %i[verify archive restore].each do |action|
      define_method(action) do
        @profile = Admin::TeacherProfiles::Transition.new(actor: current_user, profile: @profile, action:).call
        respond_to_save(action.to_s)
      end
    end

    private

    def set_profile
      @profile = TeacherProfile.includes(:user).find(params.expect(:id))
    end

    def onboarding_params
      params.expect(teacher_profile: ONBOARDING_KEYS).to_h
    end

    def update_params
      params.expect(teacher_profile: UPDATE_KEYS).to_h
    end

    def respond_to_save(message)
      if @profile.errors.empty?
        redirect_to admin_teacher_path(@profile), notice: t("teachers.messages.#{message}"), status: :see_other
      else
        template = action_name == "update" ? :edit : :show
        if template == :show
          @events = @profile.events.includes(:actor).recent_first.limit(20)
          @availabilities = @profile.availabilities.visible.chronological
        end
        render template, status: :unprocessable_content
      end
    end
  end
end
