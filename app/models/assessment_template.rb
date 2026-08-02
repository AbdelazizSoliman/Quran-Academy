class AssessmentTemplate < ApplicationRecord
  STATUSES = %w[active inactive archived].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :rubric_items, -> { order(:display_order, :id) }, class_name: "AssessmentRubricItem",
                                                               dependent: :restrict_with_exception
  has_many :student_assessments, dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AATP-[A-Z0-9]{10}\z/ }
  validates :name_ar, :name_en, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 3_000 }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :display_order, numericality: { only_integer: true, in: 0..100_000 }

  scope :ordered, -> { order(:display_order, :id) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def localized_name(locale = I18n.locale) = locale.to_s == "ar" ? name_ar : name_en

  private

  def generate_public_id = self.public_id ||= "ATP-#{SecureRandom.alphanumeric(10).upcase}"
end
