module Admin
  class FeePlansController < BaseController
    before_action :set_fee_plan, only: %i[edit update destroy]

    def index
      @fee_plans = FeePlan.ordered
      default_currency = AcademySetting.current_or_nil&.billing_currency || "EGP"
      @fee_plan = FeePlan.new(active: true, tax_percentage: 0, invoice_day: 7, currency: default_currency)
    end

    def edit; end

    def create
      @fee_plan = FeePlan.new(fee_plan_params.merge(created_by: current_user, updated_by: current_user))
      return redirect_to(admin_fee_plans_path, notice: t("fee_plans.messages.saved")) if @fee_plan.save

      @fee_plans = FeePlan.ordered
      render :index, status: :unprocessable_content
    end

    def update
      @fee_plan.assign_attributes(fee_plan_params.merge(updated_by: current_user))
      return redirect_to(admin_fee_plans_path, notice: t("fee_plans.messages.saved")) if @fee_plan.save

      render :edit, status: :unprocessable_content
    end

    def destroy
      @fee_plan.destroy
      redirect_to admin_fee_plans_path, notice: t("fee_plans.messages.deleted"), status: :see_other
    end

    private

    def set_fee_plan = @fee_plan = FeePlan.find(params.expect(:id))

    def fee_plan_params
      params.expect(fee_plan: %i[name amount currency billing_cycle tax_percentage invoice_day active])
    end
  end
end
