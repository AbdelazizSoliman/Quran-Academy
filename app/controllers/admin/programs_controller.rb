module Admin
  class ProgramsController < BaseController
    before_action :set_program, except: %i[index new create]

    def index
      @pagy, @programs = pagy(:offset, ProgramsQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @program.events.includes(:actor).recent_first.limit(20)
      @offerings = @program.course_offerings.recent_first.limit(10)
    end

    def new
      @program = Program.new
    end

    def edit; end

    def create
      @program = Programs::Create.new(actor: current_user, attributes: program_params).call
      respond_to_save("created", :new)
    end

    def update
      @program = Programs::Update.new(actor: current_user, program: @program, attributes: program_params).call
      respond_to_save("updated", :edit)
    end

    %i[activate deactivate archive restore].each do |action|
      define_method(action) do
        @program = Programs::Transition.new(actor: current_user, program: @program, action:).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_program
      @program = Program.find(params.expect(:id))
    end

    def program_params
      params.expect(program: [
                      :code, :name_ar, :name_en, :short_description_ar, :short_description_en,
                      :description_ar, :description_en, :category, :default_learning_language,
                      :entry_level, :completion_level, :default_lesson_duration_minutes,
                      :recommended_lessons_per_week, :estimated_duration_weeks, :requires_placement,
                      :allows_minor_students, :allows_adult_students, :display_order, :internal_notes,
                      { supported_learning_languages: [], target_age_groups: [] }
                    ])
    end

    def respond_to_save(message, template)
      if @program.persisted? && @program.errors.empty?
        redirect_to admin_program_path(@program), notice: t("programs.messages.#{message}"), status: :see_other
      else
        @events = @program.events.includes(:actor).recent_first.limit(20) if template == :show
        @offerings = @program.course_offerings.recent_first.limit(10) if template == :show
        render template, status: :unprocessable_content
      end
    end
  end
end
