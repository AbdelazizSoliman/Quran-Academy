module Public
  class HomeController < BaseController
    def show
      @featured_programs = PublicCatalog::ProgramPresenter.wrap(
        PublicCatalog::ProgramsQuery.new(locale: public_locale).featured, locale: public_locale
      )
      @featured_fee_plans = PublicCatalog::FeePlanPresenter.wrap(
        PublicCatalog::FeePlansQuery.new(locale: public_locale).featured, locale: public_locale
      )
    end
  end
end
