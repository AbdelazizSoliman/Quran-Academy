# Normalizes and validates locale specific public website slugs without adding a slug dependency.
module PublicWebsiteSlug
  extend ActiveSupport::Concern

  MAX_LENGTH = 120
  FORMAT = /\A\p{Alnum}+(?:-\p{Alnum}+)*\z/

  class_methods do
    def normalize_public_slug(value)
      value.to_s.unicode_normalize(:nfkc).strip.downcase
           .gsub(/[\p{Space}_]+/, "-")
           .gsub(/[^\p{Alnum}-]/, "")
           .first(MAX_LENGTH).to_s
           .gsub(/-+/, "-")
           .delete_prefix("-").delete_suffix("-")
           .presence
    end
  end
end
