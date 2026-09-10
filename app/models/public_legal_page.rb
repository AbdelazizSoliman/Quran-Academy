class PublicLegalPage < ApplicationRecord
  include PubliclyPublishable

  PAGE_TYPES = %w[privacy terms refund].freeze

  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  validates :page_type, inclusion: { in: PAGE_TYPES }, uniqueness: true
  validates :title_ar, :title_en, length: { maximum: 300 }
  validates :body_ar, :body_en, length: { maximum: 20_000 }
  validates :title_ar, :title_en, :body_ar, :body_en, presence: true, if: :published?

  scope :publicly_visible, -> { published }

  def self.for_type(type)
    find_by(page_type: type.to_s)
  end
end
