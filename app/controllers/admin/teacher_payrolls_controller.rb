module Admin
  class TeacherPayrollsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_payroll, except: %i[index new create]

    def index
      @pagy, @payrolls = pagy(:offset, TeacherPayrollsQuery.new(params:).call, limit: 25)
    end

    def show
      @items = @payroll.items.includes(scheduled_lesson: :course_offering)
      @events = @payroll.events.includes(:actor).order(created_at: :desc)
    end

    def new
      @payroll = TeacherPayroll.new(period_starts_on: Date.current.beginning_of_month,
                                    period_ends_on: Date.current.end_of_month)
    end

    def edit; end

    def create
      @payroll = TeacherPayrolls::Generate.new(actor: current_user, teacher_profile: teacher,
                                               period_starts_on: payroll_params[:period_starts_on],
                                               period_ends_on: payroll_params[:period_ends_on],
                                               strategy: payroll_params[:calculation_strategy],
                                               manual_base_amount: payroll_params[:base_amount]).call
      respond_to_save
    end

    def update
      @payroll = TeacherPayrolls::Adjust.new(actor: current_user, payroll: @payroll,
                                             attributes: payroll_params, reason: params[:adjustment_reason]).call
      respond_to_save
    end

    def prepare = transition(:prepare)
    def approve = transition(:approve)
    def mark_paid = transition(:pay)
    def reopen = transition(:reopen)
    def cancel = transition(:cancel)

    private

    def set_payroll = @payroll = TeacherPayroll.find(params.expect(:id))
    def teacher = TeacherProfile.find(payroll_params[:teacher_profile_id])

    def payroll_params
      params.expect(teacher_payroll: %i[teacher_profile_id period_starts_on period_ends_on calculation_strategy
                                        base_amount bonus_amount deduction_amount manual_adjustment_amount notes])
    end

    def transition(action)
      @payroll = TeacherPayrolls::Transition.new(actor: current_user, payroll: @payroll, action:,
                                                 reason: params[:reason]).call
      respond_to_save
    end

    def respond_to_save
      if @payroll.errors.empty?
        redirect_to admin_teacher_payroll_path(@payroll), notice: t("payroll.messages.updated"), status: :see_other
      else
        redirect_to admin_teacher_payrolls_path, alert: @payroll.errors.full_messages.to_sentence, status: :see_other
      end
    end
  end
end
