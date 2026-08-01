module Admin
  class ScheduledLessonParticipantsController < SchedulingBaseController
    before_action :require_admin!
    before_action :set_lesson

    def create
      enrollment_id = params[:scheduled_lesson_enrollment]&.[](:enrollment_id) || params.expect(:enrollment_id)
      enrollment = Enrollment.find(enrollment_id)
      @participant = ScheduledLessons::Participants::Add.new(actor: current_user, lesson: @lesson, enrollment:).call
      respond_to_save
    end

    def update
      @participant = @lesson.scheduled_lesson_enrollments.find(params.expect(:id))
      @participant = ScheduledLessons::Participants::Remove.new(actor: current_user, participant: @participant).call
      respond_to_save
    end

    private

    def set_lesson
      @lesson = ScheduledLesson.find(params.expect(:scheduled_lesson_id))
    end

    def respond_to_save
      if @participant.persisted? && @participant.errors.empty?
        redirect_to admin_scheduled_lesson_path(@lesson), notice: t("scheduling.messages.participant_updated"),
                                                          status: :see_other
      else
        redirect_to admin_scheduled_lesson_path(@lesson), alert: @participant.errors.full_messages.to_sentence,
                                                          status: :see_other
      end
    end
  end
end
