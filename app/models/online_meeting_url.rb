module OnlineMeetingUrl
  module_function

  def normalize(value)
    normalized = value.to_s.strip.gsub(%r{(https?)//}i, '\\1://')
    scheme_positions = normalized.enum_for(:scan, %r{https?://}i).map { Regexp.last_match.begin(0) }
    scheme_positions.empty? ? normalized : normalized[scheme_positions.last..]
  end

  def safe(value)
    normalized = normalize(value)
    uri = URI.parse(normalized)
    normalized if uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil? &&
                  !normalized.match?(%r{https?//}i) && !uri.path.to_s.start_with?("//")
  rescue URI::InvalidURIError
    nil
  end

  def valid?(value) = safe(value).present?
end
