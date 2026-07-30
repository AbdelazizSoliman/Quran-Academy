module Admin
  class EnrollmentsController < BaseController
    before_action :set_enrollment, except: %i[index new create]

    def index
      @pagy, @enrollments = pagy(:offset, EnrollmentsQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @enrollment.events.includes(:actor).recent_first.limit(30)
    end

    def new
      @student = StudentProfile.find_by(id: params[:student_profile_id])
      @offering = CourseOffering.find_by(id: params[:course_offering_id])
      @enrollment = Enrollment.new(student_profile: @student, course_offering: @offering)
      load_options
    end

    def edit
      load_options
    end

    def create
      load_options
      find_membership_records
      @enrollment = create_enrollment
      @enrollment.errors.add(:base, :invalid_ownership) unless @student && @offering
      respond_to_save("created", :new)
    end

    def update
      @enrollment = Enrollments::Update.new(actor: current_user, enrollment: @enrollment,
                                            attributes: enrollment_params).call
      load_options
      respond_to_save("updated", :edit)
    end

    %i[approve waitlist reject activate pause resume complete withdraw cancel transfer].each do |action|
      define_method(action) do
        @enrollment = Enrollments::Transition.new(
          actor: current_user, enrollment: @enrollment, action:,
          exit_reason: params[:exit_reason], exit_notes: params[:exit_notes]
        ).call
        respond_to_save(action.to_s, :show)
      end
    end

    %i[complete_placement waive_placement].each do |action|
      define_method(action) do
        @enrollment = Enrollments::Placement.new(
          actor: current_user, enrollment: @enrollment, action:,
          method: params[:placement_method], notes: params[:placement_notes]
        ).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_enrollment
      @enrollment = Enrollment.includes(student_profile: :user, course_offering: :program).find(params.expect(:id))
    end

    def load_options
      @students = StudentProfile.where.not(profile_status: "archived").includes(:user).order(:display_name)
      @offerings = CourseOffering.where.not(status: %w[cancelled archived
                                                       completed]).includes(:program).order(:title_en)
    end

    def find_membership_records
      @student = StudentProfile.find_by(id: params.dig(:enrollment, :student_profile_id))
      @offering = CourseOffering.find_by(id: params.dig(:enrollment, :course_offering_id))
    end

    def create_enrollment
      return Enrollment.new unless @student && @offering

      Enrollments::Create.new(actor: current_user, student_profile: @student,
                              course_offering: @offering, attributes: enrollment_params).call
    end

    def enrollment_params
      params.expect(enrollment: %i[
                      application_source student_goals_snapshot preferred_schedule_notes placement_notes
                      administrator_notes starting_quran_level starting_reading_level starting_tajweed_level
                      starting_memorization_level starting_memorized_juz_count
                    ])
    end

    def respond_to_save(message, template)
      if @enrollment.persisted? && @enrollment.errors.empty?
        redirect_to admin_enrollment_path(@enrollment),
                    notice: t("enrollments.messages.#{message}"), status: :see_other
      else
        @events = @enrollment.events.includes(:actor).recent_first.limit(30) if template == :show
        render template, status: :unprocessable_content
      end
    end
  end
end
