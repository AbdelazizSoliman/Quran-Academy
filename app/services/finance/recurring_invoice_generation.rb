module Finance
  class RecurringInvoiceGeneration
    def initialize(actor:, today: Date.current)
      @actor = actor
      @today = today
    end

    def call
      due_fee_plans.flat_map { |fee_plan| generate_for(fee_plan) }
    end

    private

    def due_fee_plans
      FeePlan.active.where(billing_cycle: "monthly").select { |fee_plan| due_today?(fee_plan) }
    end

    def due_today?(fee_plan) = @today.day == effective_invoice_day(fee_plan)

    def effective_invoice_day(fee_plan) = [fee_plan.invoice_day, period_ends_on.day].min

    def generate_for(fee_plan)
      fee_plan.student_profiles.where(learning_status: "active").filter_map do |student|
        generate_invoice(fee_plan, student)
      end
    end

    def generate_invoice(fee_plan, student)
      return if invoice_exists?(student)

      Finance::InvoiceOperation.new(actor: @actor, attributes: invoice_attributes(fee_plan, student)).create
    end

    def invoice_exists?(student)
      FinanceInvoice.exists?(student_profile_id: student.id, billing_period_starts_on: period_starts_on,
                             billing_period_ends_on: period_ends_on)
    end

    def period_starts_on = @today.beginning_of_month
    def period_ends_on = @today.end_of_month

    def invoice_attributes(fee_plan, student)
      subtotal = fee_plan.amount
      discount_amount = discount_for(subtotal, student)
      tax_amount = tax_for(subtotal - discount_amount, fee_plan)

      { student_profile_id: student.id, fee_plan_id: fee_plan.id, currency: fee_plan.currency,
        billing_period_starts_on: period_starts_on, billing_period_ends_on: period_ends_on,
        due_on: @today + 7.days, subtotal:, discount_amount:, tax_amount: }
    end

    def discount_for(subtotal, student) = (subtotal * student.discount_percentage / 100).round(2)
    def tax_for(taxable_amount, fee_plan) = (taxable_amount * fee_plan.tax_percentage / 100).round(2)
  end
end
