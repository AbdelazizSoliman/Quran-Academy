class SitemapController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_session_version!

  def show
    unless PublicWebsiteSetting.first&.enabled?
      return render xml: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>"
    end

    @urls = public_urls
    render template: "sitemap/show", formats: :xml
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def public_urls
    locales = %w[ar en]
    urls = locales.flat_map do |locale|
      [
        "/#{locale}", "/#{locale}/fees", "/#{locale}/trial", "/#{locale}/contact"
      ]
    end
    urls += locales.map { |locale| "/#{locale}/faq" } if PublicContent::FaqsQuery.new.available?
    PublicLegalPage::PAGE_TYPES.each do |type|
      next unless PublicContent::LegalPagesQuery.new.available?(type)

      slug = type == "refund" ? "refund-policy" : type
      urls.concat(locales.map { |locale| "/#{locale}/#{slug}" })
    end
    if PublicCatalog::ProgramsQuery.new(locale: "en").available?
      programs = PublicCatalog::ProgramsQuery.new(locale: "en").index(limit: 100)
      urls.concat(programs.flat_map do |program|
        ["/en/programs/#{program.slug_en}", "/ar/programs/#{program.slug_ar}"]
      end)
      urls.concat(locales.map { |locale| "/#{locale}/programs" })
    end
    urls.uniq
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
end
