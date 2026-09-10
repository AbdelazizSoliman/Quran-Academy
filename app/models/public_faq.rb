class PublicFaq < ApplicationRecord
  include PubliclyPublishable

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  validates :question_ar, :question_en, length: { maximum: 300 }
  validates :answer_ar, :answer_en, length: { maximum: 3_000 }
  validates :public_display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :question_ar, :question_en, :answer_ar, :answer_en, presence: true, if: :published?

  scope :publicly_visible, -> { published }
  scope :public_ordered, -> { order(:public_display_order, :id) }
end
