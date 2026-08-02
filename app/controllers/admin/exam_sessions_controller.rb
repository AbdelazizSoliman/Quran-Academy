module Admin
  class ExamSessionsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_exam, except: %i[index new create]

    def index
      @pagy, @exam_sessions = pagy(:offset, ExamSessionsQuery.new(params:).call, limit: 25)
    end

    def show = @events = @exam.events.includes(:actor).recent_first
    def new = @exam = ExamSession.new(starts_at: 1.week.from_now, duration_minutes: 60)
    def edit; end

    def create
      @exam = ExamSessions::Create.new(actor: current_user, attributes: exam_params).call
      respond_to_save
    end

    def update
      before = @exam.attributes.slice("title", "starts_at", "duration_minutes", "notes")
      ExamSession.transaction do
        editable = exam_params.slice(:title, :starts_at, :duration_minutes, :notes, :lock_version)
        @exam.update!(editable.merge(updated_by: current_user))
        after = @exam.attributes.slice(*before.keys)
        changed = before.keys.select { |key| before[key] != after[key] }
        if changed.any?
          @exam.events.create!(actor: current_user, event_type: "updated",
                               before_data: before.slice(*changed), after_data: after.slice(*changed))
        end
      end
      respond_to_save
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      @exam.errors.add(:base, :invalid_update)
      respond_to_save
    end

    %i[schedule complete review publish archive].each do |action|
      define_method(action) do
        @exam = ExamSessions::Transition.new(actor: current_user, exam_session: @exam, action:).call
        respond_to_save
      end
    end

    private

    def set_exam = @exam = ExamSession.find(params.expect(:id))
    def exam_params
      params.expect(exam_session: %i[title program_id course_offering_id teacher_profile_id starts_at
                                      duration_minutes notes lock_version])
    end

    def respond_to_save
      if @exam.errors.empty?
        redirect_to admin_exam_session_path(@exam), notice: t("academic.messages.saved")
      else
        render(@exam.persisted? ? :edit : :new, status: :unprocessable_content)
      end
    end
  end
end
