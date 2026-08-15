module Admin
  class StudentsController < BaseController
    before_action :set_profile, except: %i[index import import_create export new create]

    ONBOARDING_KEYS = %i[
      public_id full_name email date_of_birth gender student_type learning_status
      nationality country_of_residence city phone_number whatsapp_number
      preferred_interface_locale preferred_learning_language native_language current_quran_level
      reading_level tajweed_level memorization_level memorized_juz_count attendance_percentage
      assigned_teacher_profile_id course_offering_id fee_plan_id learning_goals
      existing_student prior_sessions_taken remaining_sessions_at_onboarding sessions_per_month
      lesson_duration_minutes weekly_lesson_count session_type trial_lesson_at weekly_price
      billing_currency schedule_generation_weeks account_delivery_method
      guardian_name guardian_email guardian_phone guardian_phone_country_code sibling_student_profile_id
      slots_json
    ].freeze

    UPDATE_KEYS = %i[
      display_name gender date_of_birth nationality country_of_residence city phone_number
      whatsapp_number preferred_contact_method preferred_interface_locale preferred_learning_language
      native_language current_quran_level reading_level tajweed_level memorization_level
      memorized_surahs memorized_juz_count learning_goals learning_notes special_learning_needs
      medical_notes safeguarding_notes emergency_contact_name emergency_contact_phone student_type
      learning_status joined_on left_on internal_notes fee_plan_id
    ].freeze

    def index
      @pagy, @profiles = pagy(:offset, Admin::MadarakStudentsQuery.new(params:).call, limit: 15)
    end

    def import; end

    def import_create
      upload = params[:file]
      unless upload.respond_to?(:tempfile)
        flash.now[:alert] = t("students.madarak.import_file_required")
        return render :import, status: :unprocessable_content
      end

      @result = Admin::StudentsCsvImport.new(actor: current_user, io: upload.tempfile).call
      if @result.errors.empty?
        redirect_to admin_students_path,
                    notice: t("students.madarak.import_success", count: @result.created_count)
      else
        flash.now[:alert] = t("students.madarak.import_partial",
                              count: @result.created_count, errors: @result.errors.size)
        render :import, status: :unprocessable_content
      end
    rescue CSV::MalformedCSVError => e
      @import_error = e.message
      render :import, status: :unprocessable_content
    end

    def export
      profiles = Admin::MadarakStudentsQuery.new(params:).call
      data = Admin::StudentsCsvExport.new(profiles).call
      send_data "\uFEFF#{data}", filename: "quran-academy-students-#{Date.current}.csv",
                                 type: "text/csv; charset=utf-8"
    end

    def show
      @events = @profile.events.includes(:actor).recent_first.limit(20)
      @guardianships = @profile.student_guardianships.includes(:guardian).recent_first
    end

    def new
      @profile = StudentProfile.new(learning_status: "active", current_quran_level: nil,
                                    country_of_residence: "EG")
      load_onboarding_collections
    end

    def edit; end

    def create
      service = Admin::Onboarding::CreateStudent.new(actor: current_user, attributes: onboarding_params)
      @profile = service.call
      if @profile.persisted? && @profile.errors.empty?
        warning = generation_warning(service.schedule)
        flash[:warning] = warning if warning
        redirect_to admin_student_path(@profile), notice: t("students.messages.created"), status: :see_other
      else
        load_onboarding_collections
        render :new, status: :unprocessable_content
      end
    end

    def update
      @profile = Admin::StudentProfiles::Update.new(actor: current_user, profile: @profile,
                                                    attributes: update_params).call
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

    # The lesson schedule (if any) already finished generating synchronously by the time the
    # onboarding service returns, so failures are visible immediately — not silently dropped.
    def generation_warning(schedule)
      return unless schedule&.persisted?

      failed = schedule.generation_issues.unresolved
      return if failed.empty?

      reasons = failed.reorder(nil).group(:reason_code).count
                      .map { |code, count| "#{code.humanize} (#{count})" }.join(", ")
      t("students.messages.generation_partial", generated: schedule.scheduled_lessons.count,
                                                failed: failed.size, reasons:)
    end

    def load_onboarding_collections
      @teacher_profiles = TeacherProfile.where.not(profile_status: "archived").order(:display_name)
      @course_offerings = CourseOffering.where(status: "open").order(:title_ar)
      @student_profiles = StudentProfile.where.not(profile_status: "archived").order(:display_name)
      @fee_plans = FeePlan.active.ordered
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
