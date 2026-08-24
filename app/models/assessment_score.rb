class AssessmentScore < ApplicationRecord
  belongs_to :student_assessment, inverse_of: :scores
  belongs_to :assessment_rubric_item

  validates :assessment_rubric_item_id, uniqueness: { scope: :student_assessment_id }
  validates :numeric_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rating, inclusion: { in: AssessmentRubricItem::RATINGS }, allow_blank: true
  validates :comments, length: { maximum: 2_000 }, allow_blank: true
  validate :rubric_consistency
  validate :score_matches_type

  def percentage
    return numeric_percentage if numeric_score.present?
    return if assessment_rubric_item.numeric? && numeric_score.nil?
    return if assessment_rubric_item.rating? && rating.blank?

    AssessmentRubricItem::RATING_PERCENTAGES[rating].to_d
  end

  private

  def numeric_percentage
    numeric_score.to_d / assessment_rubric_item.maximum_score * 100
  end

  def rubric_consistency
    return if assessment_rubric_item&.assessment_template_id == student_assessment&.assessment_template_id

    errors.add(:assessment_rubric_item, :inconsistent)
  end

  def score_matches_type
    item = assessment_rubric_item
    return unless item

    errors.add(:numeric_score, :too_high) if numeric_score.present? && numeric_score.to_d > item.maximum_score
  end
end
