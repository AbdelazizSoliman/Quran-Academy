module Admin
  module Website
    class TestimonialsController < Admin::BaseController
      before_action :set_testimonial, only: %i[edit update destroy]

      def index = @testimonials = PublicTestimonial.public_ordered
      def new = @testimonial = PublicTestimonial.new

      def edit; end

      def create
        @testimonial = PublicTestimonial.new(testimonial_params.merge(created_by: current_user,
                                                                      updated_by: current_user))
        return render :new, status: :unprocessable_content unless @testimonial.save

        redirect_to admin_website_testimonials_path, notice: t("admin.website.testimonials.messages.created"),
                                                     status: :see_other
      end

      def update
        @testimonial.assign_attributes(testimonial_params.merge(updated_by: current_user))
        return render :edit, status: :unprocessable_content unless @testimonial.save

        redirect_to admin_website_testimonials_path, notice: t("admin.website.testimonials.messages.updated"),
                                                     status: :see_other
      end

      def destroy
        @testimonial.destroy!
        redirect_to admin_website_testimonials_path, notice: t("admin.website.testimonials.messages.destroyed"),
                                                     status: :see_other
      end

      private

      def set_testimonial = @testimonial = PublicTestimonial.find(params.expect(:id))

      def testimonial_params
        params.expect(public_testimonial: %i[author_name relationship quote_ar quote_en published public_display_order])
      end
    end
  end
end
