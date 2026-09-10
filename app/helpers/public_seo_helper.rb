module PublicSeoHelper
  # rubocop:disable Metrics/MethodLength, Rails/HelperInstanceVariable
  def public_canonical_url
    public_absolute_url(public_canonical_path)
  end

  def public_page_title
    controller_name == "home" ? @public_site.seo_title : (content_for(:title).presence || @public_site.seo_title)
  end

  def public_meta_description
    return @public_site.seo_description if controller_name == "home"

    content_for(:meta_description).presence || @public_site.seo_description
  end

  def public_alternate_urls
    return {} unless public_indexable_page?

    %w[ar en].index_with { |locale| public_absolute_url(public_localized_path(locale)) }
  end

  def public_og_locale = I18n.locale.to_s == "ar" ? "ar_AR" : "en_US"

  def public_structured_data
    data = if controller_name == "home"
             {
               "@context" => "https://schema.org", "@type" => "EducationalOrganization",
               "name" => @public_site.academy_name, "url" => public_canonical_url
             }
           elsif controller_name == "faqs" && defined?(@faqs)
             {
               "@context" => "https://schema.org", "@type" => "FAQPage",
               "mainEntity" => @faqs.map do |faq|
                 {
                   "@type" => "Question", "name" => faq.question,
                   "acceptedAnswer" => { "@type" => "Answer", "text" => faq.answer }
                 }
               end
             }
           end
    data&.to_json
  end

  private

  def public_indexable_page?
    return false unless @public_site&.enabled?
    return false if controller_name == "programs" && action_name == "show"
    return false if controller_name == "legal_pages" && public_alternate_legal_page_missing?

    true
  end

  def public_localized_path(locale)
    path = request.path
    path = "/#{I18n.locale}" if path == "/"
    path.sub(%r{\A/(?:ar|en)(?=/|$)}, "/#{locale}")
  end

  def public_canonical_path
    request.path == "/" ? "/#{I18n.locale}" : request.path
  end

  def public_absolute_url(path)
    host = ENV["APP_HOST"].presence || request.host
    port = request.optional_port
    port_part = port.present? && [80, 443].exclude?(port) ? ":#{port}" : ""
    "https://#{host}#{port_part}#{path}"
  end

  def public_alternate_legal_page_missing?
    return false unless controller_name == "legal_pages" && defined?(@page_type)

    !PublicContent::LegalPagesQuery.new.available?(@page_type)
  end
end
# rubocop:enable Metrics/MethodLength, Rails/HelperInstanceVariable
