class RobotsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_session_version!

  def show
    lines = if PublicWebsiteSetting.first&.enabled?
              ["User-agent: *", "Allow: /", *disallow_lines, "Sitemap: #{sitemap_url}"]
            else
              ["User-agent: *", "Disallow: /"]
            end
    render plain: "#{lines.join("\n")}\n", content_type: "text/plain"
  end

  private

  def disallow_lines
    %w[/admin/ /dashboard /student/ /teacher/ /guardian/ /account/].map do |path|
      "Disallow: #{path}"
    end
  end

  def sitemap_url = "https://#{ENV.fetch('APP_HOST', request.host)}/sitemap.xml"
end
