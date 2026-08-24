module Teacher
  class StudentAssessmentsController < BaseController
    before_action :set_assessment, except: %i[index new create]

    def index
      prepare_workspace
    end

    def show
      @scores = @assessment.scores.includes(assessment_rubric_item: :assessment_category)
    end

    def new
      prepare_workspace
    end

    def edit
      prepare_evaluation_form?
      nil
    end

    def evaluate
      return unless prepare_evaluation_form?

      render :edit
    end

    def create
      attributes = assessment_params.merge(teacher_profile_id: current_user.teacher_profile.id)
      normalize_assessment_target!(attributes)
      @quick_scores = quick_score_params
      @assessment = StudentAssessments::Create.new(actor: current_user, attributes:,
                                                   category_scores: @quick_scores).call
      respond_to_save
    end

    def update
      @assessment = StudentAssessments::Update.new(actor: current_user, assessment: @assessment,
                                                   attributes: assessment_params, scores: score_params).call
      respond_to_save
    end

    def submit
      @assessment = StudentAssessments::Transition.new(actor: current_user, assessment: @assessment,
                                                       action: :submit).call
      respond_to_save
    end

    private

    def prepare_evaluation_form?
      unless @assessment.editable?
        head :forbidden
        return false
      end

      @scores = @assessment.scores.includes(:assessment_rubric_item)
      @enrollments = available_enrollments
      @students = available_students
      true
    end

    def set_assessment
      @assessment = StudentAssessment.where(teacher_profile: current_user.teacher_profile)
                                     .includes(:assessment_template, :student_profile).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def assessment_params
      params.expect(student_assessment: %i[enrollment_id student_profile_id scheduled_lesson_id assessment_template_id
                                           assessment_date notes lock_version])
    end

    def score_params = params.fetch(:scores, {}).to_unsafe_h

    def quick_score_params
      params.fetch(:quick_scores, {}).permit(*Assessments::MadarakTemplate::CATEGORIES.keys).to_h
    end

    def available_enrollments
      Enrollment.joins(:scheduled_lessons)
                .where(status: %w[active
                                  approved], scheduled_lessons: { teacher_profile: current_user.teacher_profile })
                .includes(student_profile: :user).distinct
    end

    def available_students
      if assessment_lesson
        assessment_lesson.scheduled_lesson_enrollments.expected
                         .includes(student_profile: :user).map(&:student_profile).uniq
      else
        available_enrollments.map(&:student_profile).uniq
      end
    end

    def assessment_lesson
      lesson_id = params[:scheduled_lesson_id] || params.dig(:student_assessment, :scheduled_lesson_id)
      return if lesson_id.blank?

      if defined?(@assessment_lesson)
        @assessment_lesson
      else
        @assessment_lesson = current_user.teacher_profile.scheduled_lessons
                                         .where(status: "completed")
                                         .find_by(id: lesson_id)
      end
    end

    def assessment_enrollment
      enrollment_id = params[:enrollment_id] || params.dig(:student_assessment, :enrollment_id)
      return if enrollment_id.blank? || assessment_lesson.blank?

      assessment_lesson.enrollments.find_by(id: enrollment_id)
    end

    def assessment_student
      assessment_enrollment&.student_profile || direct_assessment_student
    end

    def direct_assessment_student
      return if assessment_lesson.blank?

      student_id = params[:student_profile_id] || params.dig(:student_assessment, :student_profile_id)
      return if student_id.blank?

      assessment_lesson.scheduled_lesson_enrollments.expected
                       .for_student_profile_ids([student_id]).first&.student_profile
    end

    def respond_to_save
      if @assessment.errors.empty?
        redirect_to teacher_assessment_path(@assessment), notice: t("academic.messages.saved")
      else
        prepare_failed_save
        render(@assessment.persisted? ? :edit : :new, status: :unprocessable_content)
      end
    end

    def prepare_workspace
      build_workspace_assessment
      @assessments = workspace_assessments
    end

    def build_workspace_assessment
      template = Assessments::MadarakTemplate.ensure!(actor: current_user)
      @assessment = StudentAssessment.new(teacher_profile: current_user.teacher_profile,
                                          assessment_date: Date.current,
                                          enrollment: assessment_enrollment,
                                          student_profile: assessment_student,
                                          scheduled_lesson: assessment_lesson,
                                          assessment_template: template)
      @enrollments = available_enrollments
      @students = available_students
      @quick_scores = {}
    end

    def normalize_assessment_target!(attributes)
      student_id = attributes[:student_profile_id]
      return if student_id.blank?

      student_profile_id, enrollment_id = assessment_lesson ? lesson_target(student_id) : enrollment_target(student_id)
      attributes[:student_profile_id] = student_profile_id
      attributes[:enrollment_id] = enrollment_id
    end

    def lesson_target(student_id)
      participant = assessment_lesson.scheduled_lesson_enrollments.expected
                                     .for_student_profile_ids([student_id]).first
      [participant&.student_profile&.id, participant&.enrollment_id]
    end

    def enrollment_target(student_id)
      enrollment = available_enrollments.find { |candidate| candidate.student_profile_id == student_id.to_i }
      [enrollment&.student_profile_id, enrollment&.id]
    end

    def workspace_assessments
      StudentAssessmentsQuery.new(teacher_profile: current_user.teacher_profile, params:).call
                             .includes(scores: { assessment_rubric_item: :assessment_category }).limit(10)
    end

    def prepare_failed_save
      @enrollments = available_enrollments
      @students = available_students
      @assessments = workspace_assessments
      @scores = @assessment.scores.includes(:assessment_rubric_item) if @assessment.persisted?
    end
  end
end
