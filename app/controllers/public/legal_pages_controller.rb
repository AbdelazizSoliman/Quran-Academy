module Public
  class LegalPagesController < BaseController
    PAGE_PATHS = { "privacy" => :privacy, "terms" => :terms, "refund-policy" => :refund }.freeze

    def show
      @page_type = PAGE_PATHS.fetch(params[:page], params[:page])
      @legal_page = PublicContent::LegalPagesQuery.new.find(@page_type)
      return render("not_found", status: :not_found) unless @legal_page

      @legal_page = PublicContent::LegalPagePresenter.new(@legal_page, locale: public_locale)
    end
  end
end
