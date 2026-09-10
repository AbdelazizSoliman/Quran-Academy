module Public
  class FaqsController < BaseController
    def index
      return head :not_found unless public_faqs_available?

      @faqs = PublicContent::FaqPresenter.wrap(PublicContent::FaqsQuery.new.index, locale: public_locale)
    end
  end
end
