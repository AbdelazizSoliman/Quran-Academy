module Admin
  module Website
    class FeePlansController < Admin::BaseController
      before_action :set_fee_plan, only: %i[edit update]

      def index
        @fee_plans = FeePlan.order(:public_display_order, :name, :id)
      end

      def edit; end

      def update
        @fee_plan.assign_attributes(fee_plan_params.merge(updated_by: current_user))
        return render :edit, status: :unprocessable_content unless @fee_plan.save

        redirect_to admin_website_fee_plans_path, notice: t("admin.website.fee_plans.messages.updated"),
                                                  status: :see_other
      end

      private

      def set_fee_plan = @fee_plan = FeePlan.find(params.expect(:id))

      def fee_plan_params
        params.expect(fee_plan: %i[
                        published name_ar name_en description_ar description_en
                        public_features_ar public_features_en price_note_ar price_note_en
                        public_cta_label_ar public_cta_label_en public_display_order
                      ])
      end
    end
  end
end
