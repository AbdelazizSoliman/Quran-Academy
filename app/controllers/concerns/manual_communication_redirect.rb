require "uri"

module ManualCommunicationRedirect
  private

  def redirect_to_external_communication(log)
    uri = URI.parse(log.external_url.to_s)
    return head :bad_request unless allowed_communication_uri?(uri)

    response.location = uri.to_s
    head :see_other
  rescue URI::InvalidURIError
    head :bad_request
  end

  def allowed_communication_uri?(uri)
    uri.is_a?(URI::MailTo) || (uri.is_a?(URI::HTTPS) && uri.host == "wa.me")
  end
end
