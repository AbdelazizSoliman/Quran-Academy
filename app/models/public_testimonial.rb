class PublicTestimonial < ApplicationRecord
  include PubliclyPublishable

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  validates :author_name, length: { maximum: 200 }, allow_blank: true
  validates :relationship, length: { maximum: 200 }, presence: true
  validates :quote_ar, :quote_en, length: { maximum: 2_000 }
  validates :public_display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quote_ar, :quote_en, presence: true, if: :published?

  scope :publicly_visible, -> { published }
  scope :public_ordered, -> { order(:public_display_order, :id) }
end
