module Teacher
  class LessonEvaluationsController < BaseController
    before_action :set_lesson

    def show
      load_workspace
    end

    def submit
      load_workspace
      return redirect_for_missing_assessments if missing_assessments.any?

      failures = submit_drafts
      redirect_after_submission(failures)
    end

    private

    def set_lesson
      @lesson = current_user.teacher_profile.scheduled_lessons.where(status: "completed")
                            .find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def load_workspace
      @participants = @lesson.scheduled_lesson_enrollments.expected
                             .includes(:lesson_attendance, enrollment: { student_profile: :user },
                                                           student_profile: :user).to_a
      @eligible_participants = @participants.reject do |participant|
        participant.lesson_attendance&.status.in?(%w[absent excused_absence lesson_cancelled not_applicable])
      end
      assessments = StudentAssessment.where(
        teacher_profile: current_user.teacher_profile,
        scheduled_lesson: @lesson
      )
                                     .includes(:student_profile,
                                               scores: { assessment_rubric_item: :assessment_category })
      @assessments_by_student = assessments.index_by(&:student_profile_id)
      @completed_count = @eligible_participants.count { |p| @assessments_by_student[p.student_profile.id].present? }
    end

    def missing_assessments
      @missing_assessments ||= @eligible_participants.reject do |participant|
        @assessments_by_student[participant.student_profile.id]
      end
    end

    def redirect_for_missing_assessments
      redirect_to evaluations_teacher_schedule_path(@lesson),
                  alert: t("academic.lesson_evaluations.complete_first", count: missing_assessments.size)
    end

    def redirect_after_submission(failures)
      if failures.present?
        redirect_to evaluations_teacher_schedule_path(@lesson), alert: failures
      else
        redirect_to evaluations_teacher_schedule_path(@lesson),
                    notice: t("academic.lesson_evaluations.submitted", count: draft_assessments.size)
      end
    end

    def draft_assessments
      @draft_assessments ||= @assessments_by_student.values.select(&:draft?)
    end

    def submit_drafts
      draft_assessments.filter_map do |assessment|
        result = StudentAssessments::Transition.new(actor: current_user, assessment:, action: :submit).call
        result.errors.full_messages if result.errors.any?
      end.flatten.to_sentence
    end
  end
end
