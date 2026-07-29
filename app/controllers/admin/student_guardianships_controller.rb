module Admin
  class StudentGuardianshipsController < BaseController
    before_action :set_student
    before_action :set_guardianship, except: %i[create create_guardian]

    def create
      guardian = Guardian.find_by(id: params.dig(:student_guardianship, :guardian_id))
      @guardianship = guardian && StudentGuardianships::Create.new(
        actor: current_user, student_profile: @student, guardian:, attributes: guardianship_params
      ).call
      if @guardianship&.persisted?
        redirect_to admin_student_path(@student), notice: t("guardianships.messages.created"), status: :see_other
      else
        redirect_to admin_student_path(@student), alert: t("guardianships.messages.failed"), status: :see_other
      end
    end

    def create_guardian
      operation = StudentGuardianships::CreateGuardianAndAttach.new(
        actor: current_user, student_profile: @student,
        guardian_attributes: create_guardian_params,
        relationship_attributes: guardianship_params
      ).call
      key = operation.success? ? "created" : "failed"
      flash_key = operation.success? ? :notice : :alert
      redirect_to admin_student_path(@student), flash_key => t("guardianships.messages.#{key}"), status: :see_other
    end

    def update
      @guardianship = StudentGuardianships::Update.new(
        actor: current_user, guardianship: @guardianship, attributes: guardianship_params
      ).call
      respond
    end

    %i[make_primary end restore].each do |action|
      define_method(action) do
        @guardianship = StudentGuardianships::Transition.new(
          actor: current_user, guardianship: @guardianship, action:, replacement_id: params[:replacement_id]
        ).call
        respond
      end
    end

    private

    def set_student
      @student = StudentProfile.find(params.expect(:student_id))
    end

    def set_guardianship
      @guardianship = @student.student_guardianships.find(params.expect(:id))
    end

    def guardianship_params
      params.expect(student_guardianship: %i[
                      relationship_type custom_relationship emergency_contact legal_guardian
                      can_make_academic_decisions receives_academic_updates receives_billing_updates
                      starts_on ends_on notes
                    ])
    end

    def create_guardian_params
      params.expect(guardian: %i[
                      full_name gender email phone_number whatsapp_number preferred_contact_method
                      preferred_language country city occupation internal_notes
                    ])
    end

    def respond
      key = @guardianship.errors.empty? ? "updated" : "failed"
      flash_key = @guardianship.errors.empty? ? :notice : :alert
      redirect_to admin_student_path(@student), flash_key => t("guardianships.messages.#{key}"), status: :see_other
    end
  end
end
