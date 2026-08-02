class AssessmentRubricItem < ApplicationRecord
  SCORING_TYPES = %w[numeric rating].freeze
  RATINGS = %w[excellent very_good good fair poor].freeze
  RATING_PERCENTAGES = { "excellent" => 100, "very_good" => 85, "good" => 75,
                         "fair" => 60, "poor" => 40 }.freeze

  belongs_to :assessment_template, inverse_of: :rubric_items
  belongs_to :assessment_category, inverse_of: :rubric_items
  has_many :assessment_scores, dependent: :restrict_with_exception

  validates :name_ar, :name_en, presence: true, length: { maximum: 200 }
  validates :scoring_type, inclusion: { in: SCORING_TYPES }
  validates :maximum_score, :weight, numericality: { greater_than: 0 }
  validates :display_order, numericality: { only_integer: true, in: 0..100_000 }

  def localized_name(locale = I18n.locale) = locale.to_s == "ar" ? name_ar : name_en
  SCORING_TYPES.each { |value| define_method(:"#{value}?") { scoring_type == value } }
end
