module Assessments
  class GradeCalculator
    DEFAULT_BOUNDARIES = { "A+" => 95, "A" => 90, "B+" => 85, "B" => 80,
                           "C" => 70, "D" => 60, "F" => 0 }.freeze

    def initialize(scores:, boundaries: AcademySetting.current.assessment_grade_boundaries)
      @scores = scores
      @boundaries = boundaries.presence || DEFAULT_BOUNDARIES
    end

    def call
      scored = @scores.select { |score| score.assessment_rubric_item && score.percentage }
      return { percentage: nil, letter_grade: nil } if scored.empty?

      total_weight = scored.sum { |score| score.assessment_rubric_item.weight }
      percentage = scored.sum { |score| score.percentage * score.assessment_rubric_item.weight } / total_weight
      percentage = percentage.round(2)
      { percentage:, letter_grade: grade_for(percentage) }
    end

    private

    def grade_for(percentage)
      @boundaries.sort_by { |_grade, minimum| -minimum.to_d }.find do |_grade, minimum|
        percentage >= minimum.to_d
      end&.first || "F"
    end
  end
end
