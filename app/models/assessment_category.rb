class AssessmentCategory < ApplicationRecord
  CODES = %w[memorization revision tajweed fluency attendance homework participation discipline behavior].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :rubric_items, class_name: "AssessmentRubricItem", dependent: :restrict_with_exception

  attr_readonly :public_id, :code
  before_validation :generate_public_id, on: :create
  before_validation { self.code = code.to_s.downcase }

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AACG-[A-Z0-9]{10}\z/ }
  validates :code, presence: true, uniqueness: true, inclusion: { in: CODES }
  validates :name_ar, :name_en, presence: true, length: { maximum: 150 }
  validates :display_order, numericality: { only_integer: true, in: 0..100_000 }

  scope :ordered, -> { order(:display_order, :id) }
  def localized_name(locale = I18n.locale) = locale.to_s == "ar" ? name_ar : name_en

  private

  def generate_public_id = self.public_id ||= "ACG-#{SecureRandom.alphanumeric(10).upcase}"
end
