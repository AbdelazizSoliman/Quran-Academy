module Admin
  class StudentObservationsController < BaseController
    before_action :set_student

    def create
      observation = StudentObservations::Create.new(actor: current_user, student_profile: @student,
                                                    teacher_profile: current_user.teacher_profile,
                                                    attributes: observation_params).call
      if observation.errors.empty?
        redirect_to admin_student_learning_profile_path(@student), notice: t("learning_profile.observation_saved")
      else
        redirect_to admin_student_learning_profile_path(@student), alert: observation.errors.full_messages.to_sentence
      end
    end

    private

    def set_student = @student = StudentProfile.find(params.expect(:student_id))

    def observation_params
      params.fetch(:observation, {}).permit(:category, :observation, :observed_at,
                                            :scheduled_lesson_id, :sensitivity, :visibility)
    end
  end
end
