module Public
  class ProgramsController < BaseController
    def index
      @programs = PublicCatalog::ProgramPresenter.wrap(programs_query.index, locale: public_locale)
    end

    def show
      program = programs_query.find_published_by_slug(params[:slug])
      return render("not_found", status: :not_found) if program.nil?

      @program = PublicCatalog::ProgramPresenter.new(program, locale: public_locale)
    end

    private

    def programs_query = PublicCatalog::ProgramsQuery.new(locale: public_locale)
  end
end
