module Admin
  module Website
    class FaqsController < Admin::BaseController
      before_action :set_faq, only: %i[edit update destroy]

      def index = @faqs = PublicFaq.public_ordered
      def new = @faq = PublicFaq.new

      def edit; end

      def create
        @faq = PublicFaq.new(faq_params.merge(created_by: current_user, updated_by: current_user))
        return render :new, status: :unprocessable_content unless @faq.save

        redirect_to admin_website_faqs_path, notice: t("admin.website.faqs.messages.created"), status: :see_other
      end

      def update
        @faq.assign_attributes(faq_params.merge(updated_by: current_user))
        return render :edit, status: :unprocessable_content unless @faq.save

        redirect_to admin_website_faqs_path, notice: t("admin.website.faqs.messages.updated"), status: :see_other
      end

      def destroy
        @faq.destroy!
        redirect_to admin_website_faqs_path, notice: t("admin.website.faqs.messages.destroyed"), status: :see_other
      end

      private

      def set_faq = @faq = PublicFaq.find(params.expect(:id))

      def faq_params
        params.expect(public_faq: %i[question_ar question_en answer_ar answer_en published
                                     public_display_order])
      end
    end
  end
end
