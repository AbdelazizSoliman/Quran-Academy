module Admin
  class StudentAssessmentsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_assessment, except: %i[index new create]

    def index
      @pagy, @assessments = pagy(:offset, StudentAssessmentsQuery.new(params:).call, limit: 25)
      load_filter_options
    end

    def show
      @scores = @assessment.scores.includes(assessment_rubric_item: :assessment_category)
      @events = @assessment.events.includes(:actor).recent_first
    end

    def new
      @assessment = StudentAssessment.new(assessment_date: Date.current)
      load_quick_form_options
      @quick_scores = {}
    end

    def edit
      @scores = @assessment.scores.includes(:assessment_rubric_item)
      @enrollments = available_enrollments
    end

    def create
      template = Assessments::MadarakTemplate.ensure!(actor: current_user)
      attributes = assessment_params.merge(assessment_template_id: template.id)
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

    %i[submit review publish archive].each do |action|
      define_method(action) do
        @assessment = StudentAssessments::Transition.new(actor: current_user, assessment: @assessment,
                                                        action:).call
        respond_to_save
      end
    end

    private

    def set_assessment
      @assessment = StudentAssessment.includes(:assessment_template, :student_profile, :teacher_profile)
                                     .find(params.expect(:id))
    end

    def assessment_params
      params.expect(student_assessment: %i[enrollment_id teacher_profile_id scheduled_lesson_id
                                            assessment_template_id assessment_date notes lock_version])
    end

    def score_params
      params.fetch(:scores, {}).to_unsafe_h
    end

    def quick_score_params
      params.fetch(:quick_scores, {}).permit(*Assessments::MadarakTemplate::CATEGORIES.keys).to_h
    end

    def available_enrollments
      Enrollment.where(status: %w[active approved]).includes(student_profile: :user)
                .order(:student_profile_id, :id)
    end

    def load_quick_form_options
      @enrollments = available_enrollments
      @teachers = TeacherProfile.available_for_scheduling.order(:display_name)
    end

    def load_filter_options
      @students = StudentProfile.includes(:user).order(:display_name)
      @teachers = TeacherProfile.order(:display_name)
      @templates = AssessmentTemplate.ordered
    end

    def respond_to_save
      if @assessment.errors.empty?
        redirect_to admin_student_assessment_path(@assessment), notice: t("academic.messages.saved")
      else
        load_quick_form_options unless @assessment.persisted?
        @scores = @assessment.scores.includes(:assessment_rubric_item) if @assessment.persisted?
        flash.now[:alert] = @assessment.errors.full_messages.to_sentence
        render(@assessment.persisted? ? :edit : :new, status: :unprocessable_content)
      end
    end
  end
end
