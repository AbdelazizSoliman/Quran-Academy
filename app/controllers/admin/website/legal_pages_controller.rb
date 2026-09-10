module Admin
  module Website
    class LegalPagesController < Admin::BaseController
      before_action :set_page, only: %i[edit update]

      def index
        @legal_pages = PublicLegalPage.order(:page_type)
      end

      def edit; end

      def update
        @legal_page.assign_attributes(legal_page_params.merge(updated_by: current_user))
        @legal_page.created_by ||= current_user
        return render :edit, status: :unprocessable_content unless @legal_page.save

        redirect_to admin_website_legal_pages_path, notice: t("admin.website.legal_pages.messages.updated"),
                                                    status: :see_other
      end

      private

      def set_page
        @legal_page = PublicLegalPage.find_or_initialize_by(page_type: params.expect(:id))
      end

      def legal_page_params
        params.expect(public_legal_page: %i[title_ar title_en body_ar body_en published effective_date])
      end
    end
  end
end
