# Shared publication lifecycle for records presented on the public website.
#
# `published` is the only authoritative publication switch. `published_at` records when a record
# was first made public: it is stamped on the first transition to published and is never cleared,
# so unpublishing and republishing keeps one auditable first-publication timestamp.
module PubliclyPublishable
  extend ActiveSupport::Concern

  included do
    before_save :stamp_published_at

    scope :published, -> { where(published: true) }
  end

  private

  def stamp_published_at
    self.published_at ||= Time.current if published?
  end
end
