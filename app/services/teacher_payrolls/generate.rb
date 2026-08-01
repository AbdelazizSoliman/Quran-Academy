module TeacherPayrolls
  class Generate
    def initialize(actor:, teacher_profile:, period_starts_on:, period_ends_on:, **options)
      @actor = actor
      @teacher = teacher_profile
      @starts_on = period_starts_on.to_date
      @ends_on = period_ends_on.to_date
      @strategy = normalize_strategy(options[:strategy] || teacher_profile.compensation_unit)
      @manual_base_amount = options[:manual_base_amount]
    end

    def call
      return invalid(:forbidden) unless @actor.active? && @actor.admin?

      existing = TeacherPayroll.find_by(teacher_profile: @teacher, period_starts_on: @starts_on,
                                        period_ends_on: @ends_on)
      return existing if existing

      TeacherPayroll.transaction { generate! }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, ArgumentError
      TeacherPayroll.find_by(teacher_profile: @teacher, period_starts_on: @starts_on,
                             period_ends_on: @ends_on) || invalid(:generation_failed)
    end

    private

    def generate!
      payroll = TeacherPayroll.create!(teacher_profile: @teacher, period_starts_on: @starts_on,
                                       period_ends_on: @ends_on, calculation_strategy: @strategy,
                                       currency: @teacher.compensation_currency, rate: @teacher.default_lesson_rate,
                                       base_amount: base_amount, created_by: @actor, updated_by: @actor)
      create_items!(payroll)
      payroll.recalculate_net
      payroll.save!
      audit!(payroll)
      payroll
    end

    def lessons
      @lessons ||= @teacher.scheduled_lessons.where(status: "completed", starts_at: period_range).chronological
    end

    def period_range = @starts_on.beginning_of_day..@ends_on.end_of_day

    def base_amount
      case @strategy
      when "per_lesson" then lessons.count * @teacher.default_lesson_rate
      when "hourly" then lesson_minutes * @teacher.default_lesson_rate / 60
      when "monthly_fixed" then @teacher.default_lesson_rate
      when "manual_amount" then BigDecimal(@manual_base_amount.to_s)
      end
    end

    def lesson_minutes = lessons.sum { |lesson| ((lesson.ends_at - lesson.starts_at) / 60).round }

    def create_items!(payroll)
      lessons.find_each do |lesson|
        minutes = ((lesson.ends_at - lesson.starts_at) / 60).round
        payroll.items.create!(scheduled_lesson: lesson, duration_minutes: minutes,
                              rate: payroll.rate, amount: item_amount(minutes, payroll.rate))
      end
    end

    def item_amount(minutes, rate)
      return rate if @strategy == "per_lesson"
      return minutes * rate / 60 if @strategy == "hourly"

      0
    end

    def normalize_strategy(value)
      { "per_hour" => "hourly", "monthly" => "monthly_fixed" }.fetch(value.to_s, value.to_s)
    end

    def audit!(payroll)
      TeacherPayrollEvent.create!(teacher_payroll: payroll, actor: @actor, event_type: "generated",
                                  after_data: { "status" => "draft", "base_amount" => payroll.base_amount.to_s })
    end

    def invalid(error)
      payroll = TeacherPayroll.new(teacher_profile: @teacher, period_starts_on: @starts_on,
                                   period_ends_on: @ends_on, calculation_strategy: @strategy,
                                   currency: @teacher.compensation_currency, created_by: @actor, updated_by: @actor)
      payroll.errors.add(:base, error)
      payroll
    end
  end
end
