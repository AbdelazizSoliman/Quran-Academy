module Teacher
  class StudentAssessmentsController < BaseController
    before_action :set_assessment, except: %i[index new create]

    def index
      @assessments = StudentAssessmentsQuery.new(teacher_profile: current_user.teacher_profile, params:).call
    end

    def show
      @scores = @assessment.scores.includes(assessment_rubric_item: :assessment_category)
    end

    def new
      @assessment = StudentAssessment.new(teacher_profile: current_user.teacher_profile,
                                           assessment_date: Date.current)
      @enrollments = available_enrollments
    end

    def edit
      return head :forbidden unless @assessment.editable?

      @scores = @assessment.scores.includes(:assessment_rubric_item)
      @enrollments = available_enrollments
    end

    def create
      attributes = assessment_params.merge(teacher_profile_id: current_user.teacher_profile.id)
      @assessment = StudentAssessments::Create.new(actor: current_user, attributes:).call
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

    def set_assessment
      @assessment = StudentAssessment.where(teacher_profile: current_user.teacher_profile)
                                     .includes(:assessment_template, :student_profile).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def assessment_params
      params.expect(student_assessment: %i[enrollment_id scheduled_lesson_id assessment_template_id
                                            assessment_date notes lock_version])
    end

    def score_params = params.fetch(:scores, {}).to_unsafe_h

    def available_enrollments
      Enrollment.joins(:scheduled_lessons)
                .where(status: %w[active approved], scheduled_lessons: { teacher_profile: current_user.teacher_profile })
                .includes(student_profile: :user).distinct
    end

    def respond_to_save
      if @assessment.errors.empty?
        redirect_to teacher_assessment_path(@assessment), notice: t("academic.messages.saved")
      else
        @enrollments = available_enrollments
        @scores = @assessment.scores.includes(:assessment_rubric_item) if @assessment.persisted?
        render(@assessment.persisted? ? :edit : :new, status: :unprocessable_content)
      end
    end
  end
end
