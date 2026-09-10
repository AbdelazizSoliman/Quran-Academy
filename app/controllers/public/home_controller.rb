module Public
  class HomeController < BaseController
    def show
      @featured_programs = featured_programs
      @featured_fee_plans = PublicCatalog::FeePlanPresenter.wrap(
        PublicCatalog::FeePlansQuery.new(locale: public_locale).featured, locale: public_locale
      )
      @faqs = PublicContent::FaqPresenter.wrap(PublicContent::FaqsQuery.new.homepage, locale: public_locale)
      @testimonials = PublicContent::TestimonialPresenter.wrap(
        PublicContent::TestimonialsQuery.new.homepage, locale: public_locale
      )
    end

    private

    def featured_programs
      return [] unless public_programs_available?

      programs = PublicCatalog::ProgramsQuery.new(locale: public_locale).featured
      PublicCatalog::ProgramPresenter.wrap(programs, locale: public_locale)
    end
  end
end
