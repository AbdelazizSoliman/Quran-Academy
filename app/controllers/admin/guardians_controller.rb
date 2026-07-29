module Admin
  class GuardiansController < BaseController
    before_action :set_guardian, except: %i[index new create]

    def index
      @pagy, @guardians = pagy(:offset, GuardiansQuery.new(params:).call, limit: 15)
    end

    def show
      @events = @guardian.events.includes(:actor).recent_first.limit(20)
      @guardianships = @guardian.student_guardianships.includes(student_profile: :user).recent_first
    end

    def new
      @guardian = Guardian.new
    end

    def edit; end

    def create
      operation = Guardians::Create.new(actor: current_user, attributes: guardian_params)
      @guardian = operation.call
      @duplicate_candidates = operation.duplicate_candidates
      respond_to_save("created", :new)
    end

    def update
      @guardian = Guardians::Update.new(actor: current_user, guardian: @guardian, attributes: guardian_params).call
      respond_to_save("updated", :edit)
    end

    %i[archive restore].each do |action|
      define_method(action) do
        @guardian = Guardians::Transition.new(actor: current_user, guardian: @guardian, action:).call
        respond_to_save(action.to_s, :show)
      end
    end

    private

    def set_guardian
      @guardian = Guardian.find(params.expect(:id))
    end

    def guardian_params
      params.expect(guardian: %i[
                      full_name gender email phone_number whatsapp_number preferred_contact_method
                      preferred_language country city occupation internal_notes
                    ])
    end

    def respond_to_save(message, template)
      if @guardian.persisted? && @guardian.errors.empty?
        redirect_to admin_guardian_path(@guardian), notice: t("guardians.messages.#{message}"), status: :see_other
      else
        @events = @guardian.events.includes(:actor).recent_first.limit(20) if template == :show
        if template == :show
          @guardianships = @guardian.student_guardianships.includes(student_profile: :user).recent_first
        end
        render template, status: :unprocessable_content
      end
    end
  end
end
