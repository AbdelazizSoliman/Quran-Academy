module Admin
  module Website
    class LeadsController < Admin::BaseController
      before_action :set_lead, only: %i[show update]

      def index
        scope = PublicInquiry.recent_first
        filters = params.permit(:type, :status)
        scope = scope.where(inquiry_type: filters[:type]) if filters[:type].in?(PublicInquiry::TYPES)
        scope = scope.where(status: filters[:status]) if filters[:status].in?(PublicInquiry::STATUSES)
        @pagy, @leads = pagy(:offset, scope, limit: 25)
      end

      def show; end

      def update
        attributes = lead_params
        if attributes[:status].present? && attributes[:status] != "new" && @lead.handled_at.nil?
          attributes = attributes.merge(handled_at: Time.current, handled_by: current_user)
        end

        if @lead.update(attributes)
          redirect_to admin_website_lead_path(@lead),
                      notice: t("admin.website.leads.messages.updated"), status: :see_other
        else
          render :show, status: :unprocessable_content
        end
      end

      private

      def set_lead = @lead = PublicInquiry.find(params.expect(:id))
      def lead_params = params.expect(public_inquiry: %i[status internal_notes])
    end
  end
end
