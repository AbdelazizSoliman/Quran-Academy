module TeacherPayrolls
  class Adjust
    FIELDS = %w[bonus_amount deduction_amount manual_adjustment_amount notes].freeze

    def initialize(actor:, payroll:, attributes:, reason:)
      @actor = actor
      @payroll = payroll
      @attributes = attributes.to_h.slice(*FIELDS, *FIELDS.map(&:to_sym))
      @reason = reason.to_s.strip
    end

    def call
      return invalid(:forbidden) unless @actor.active? && @actor.admin?
      return invalid(:not_editable) unless @payroll.draft?

      TeacherPayroll.transaction { adjust! }
      @payroll
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def adjust!
      @payroll.assign_attributes(@attributes)
      changes = @payroll.changes.slice(*FIELDS)
      return if changes.empty?

      require_reason!
      @payroll.assign_attributes(adjustment_reason: @reason, updated_by: @actor)
      @payroll.recalculate_net
      @payroll.save!
      create_event!(changes)
    end

    def require_reason!
      return if @reason.present?

      @payroll.errors.add(:base, :reason_required)
      raise ActiveRecord::RecordInvalid, @payroll
    end

    def create_event!(changes)
      TeacherPayrollEvent.create!(teacher_payroll: @payroll, actor: @actor, event_type: "adjusted",
                                  before_data: changes.transform_values(&:first),
                                  after_data: changes.transform_values(&:last), metadata: { "reason" => @reason })
    end

    def invalid(error)
      @payroll.errors.add(:base, error)
      @payroll
    end
  end
end
