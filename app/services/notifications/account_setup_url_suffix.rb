require "uri"

module Notifications
  class AccountSetupUrlSuffix
    def self.call(invitation_url:, configured_prefix: ENV.fetch("WHATSAPP_ACCOUNT_SETUP_URL_PREFIX", nil))
      new(invitation_url:, configured_prefix:).call
    end

    def initialize(invitation_url:, configured_prefix:)
      @invitation_url = invitation_url
      @configured_prefix = configured_prefix
    end

    def call
      invitation, prefix = parsed_urls
      return unless matching_urls?(invitation, prefix)

      extract_suffix(invitation, prefix)
    rescue URI::InvalidURIError
      nil
    end

    private

    def parsed_urls
      [URI.parse(@invitation_url.to_s), URI.parse(@configured_prefix.to_s)]
    end

    def matching_urls?(invitation, prefix)
      valid_absolute_http_uri?(invitation) && valid_prefix?(prefix) &&
        same_origin?(invitation, prefix) && invitation.path.start_with?(prefix.path)
    end

    def extract_suffix(invitation, prefix)
      path_suffix = invitation.path.delete_prefix(prefix.path)
      return if path_suffix.blank? || path_suffix.start_with?("/")

      [path_suffix, invitation.query].compact.join("?")
    end

    def valid_absolute_http_uri?(uri)
      uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil? && uri.fragment.nil?
    end

    def valid_prefix?(uri)
      valid_absolute_http_uri?(uri) && uri.query.nil? && uri.path.end_with?("/")
    end

    def same_origin?(left, right)
      left.scheme == right.scheme && left.host == right.host && left.port == right.port
    end
  end
end
