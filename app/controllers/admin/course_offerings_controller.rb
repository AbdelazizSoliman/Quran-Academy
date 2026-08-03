module Admin
  class CourseOfferingsController < BaseController
    before_action :set_offering, except: %i[index new create]

    def index
      @pagy, @offerings = pagy(:offset, CourseOfferingsQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @offering.events.includes(:actor).recent_first.limit(20)
      @status_counts = @offering.enrollments.group(:status).count
    end

    def new
      @program = Program.find_by(id: params[:program_id])
      @offering = build_offering
      load_programs
    end

    def edit
      load_programs
    end

    def create
      load_programs
      @program = @programs.find_by(id: params.dig(:course_offering, :program_id))
      @offering = if @program
                    CourseOfferings::Create.new(actor: current_user, program: @program,
                                                attributes: offering_params).call
                  else
                    CourseOffering.new
                  end
      @offering.errors.add(:program, :invalid) unless @program
      respond_to_save("created", :new)
    end

    def update
      @programs = Program.where.not(status: "archived").order(:name_en)
      @offering = CourseOfferings::Update.new(actor: current_user, offering: @offering,
                                              attributes: offering_params).call
      respond_to_save("updated", :edit)
    end

    %i[open close start complete cancel archive restore].each do |action|
      define_method(action) do
        @offering = CourseOfferings::Transition.new(actor: current_user, offering: @offering, action:).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_offering
      @offering = CourseOffering.includes(:program).find(params.expect(:id))
    end

    def load_programs
      @programs = Program.where.not(status: "archived").order(:name_en)
    end

    def build_offering
      return CourseOffering.new unless @program

      @program.course_offerings.build(
        learning_language: @program.default_learning_language,
        target_age_groups: @program.target_age_groups,
        default_lesson_duration_minutes: @program.default_lesson_duration_minutes,
        intended_lessons_per_week: @program.recommended_lessons_per_week,
        placement_required: @program.requires_placement
      )
    end

    def offering_params
      params.expect(course_offering: [
                      :code, :title_ar, :title_en, :description_ar, :description_en,
                      :learning_language, :delivery_mode, :enrollment_opens_on,
                      :enrollment_closes_on, :planned_start_on, :planned_end_on, :capacity,
                      :default_lesson_duration_minutes, :intended_lessons_per_week,
                      :placement_required, :internal_notes, { target_age_groups: [] }
                    ])
    end

    def respond_to_save(message, template)
      if @offering.persisted? && @offering.errors.empty?
        redirect_to admin_course_offering_path(@offering),
                    notice: t("course_offerings.messages.#{message}"), status: :see_other
      elsif template == :show
        redirect_to admin_course_offering_path(@offering), alert: @offering.errors.full_messages.to_sentence,
                                                           status: :see_other
      else
        render template, status: :unprocessable_content
      end
    end
  end
end
