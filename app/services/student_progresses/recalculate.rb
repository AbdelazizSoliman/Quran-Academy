module StudentProgresses
  class Recalculate
    def initialize(student_profile:, actor: nil)
      @student_profile = student_profile
      @actor = actor
    end

    def call
      assessments = StudentAssessment.where(status: "published", student_profile: @student_profile).recent_first
      progress = StudentProgress.find_or_initialize_by(student_profile: @student_profile)
      progress.assign_attributes(summary_attributes(assessments).merge(updated_by: @actor))
      progress.save!
      progress
    end

    private

    def summary_attributes(assessments)
      scores = assessments.where.not(overall_score: nil).pluck(:overall_score)
      latest = assessments.first
      strongest, weakest = category_extremes(assessments)
      { average_score: average(scores), highest_score: scores.max, lowest_score: scores.min,
        latest_assessment: latest, last_evaluation_date: latest&.assessment_date,
        strongest_category: strongest, weakest_category: weakest, trend: trend(scores) }
    end

    def category_extremes(assessments)
      scores = AssessmentScore.includes(:assessment_rubric_item)
                              .where(student_assessment_id: assessments.select(:id))
      values = scores.filter_map do |score|
        percentage = score.percentage
        [score.assessment_rubric_item.assessment_category_id, percentage] if percentage
      end
      averages = values.group_by(&:first).transform_values do |entries|
        entries.sum { |_category_id, percentage| percentage } / entries.size
      end
      return [nil, nil] if averages.empty?

      [AssessmentCategory.find_by(id: averages.max_by { |_id, value| value }&.first),
       AssessmentCategory.find_by(id: averages.min_by { |_id, value| value }&.first)]
    end

    def average(scores) = scores.any? ? (scores.sum / scores.size).round(2) : nil

    def trend(scores)
      return "stable" if scores.size < 2

      delta = scores.first.to_d - scores.last.to_d
      return "improving" if delta >= 5
      return "needs_attention" if delta <= -5

      "stable"
    end
  end
end
