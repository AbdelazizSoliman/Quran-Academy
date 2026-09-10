xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  @urls.each do |path|
    xml.url { xml.loc("https://#{ENV.fetch("APP_HOST", request.host)}#{path}") }
  end
end
