module Public
  class FeesController < BaseController
    def index
      @fee_plans = PublicCatalog::FeePlanPresenter.wrap(
        PublicCatalog::FeePlansQuery.new(locale: public_locale).index, locale: public_locale
      )
    end
  end
end
