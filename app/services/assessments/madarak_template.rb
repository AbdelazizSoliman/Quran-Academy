module Assessments
  class MadarakTemplate
    NAME_EN = "Madarak Weekly Evaluation".freeze
    CATEGORIES = {
      "memorization" => ["الحفظ", "Memorization"],
      "tajweed" => ["التجويد", "Tajweed"],
      "attendance" => ["الحضور", "Attendance"],
      "behavior" => ["السلوك", "Behavior"]
    }.freeze

    def self.ensure!(actor:)
      new(actor:).ensure!
    end

    def initialize(actor:)
      @actor = actor
    end

    def ensure!
      AssessmentTemplate.transaction do
        template = AssessmentTemplate.find_or_initialize_by(name_en: NAME_EN)
        template.assign_attributes(name_ar: "التقييم الأسبوعي", status: "active", display_order: 0,
                                   created_by: template.created_by || @actor, updated_by: @actor)
        template.save!
        ensure_rubrics!(template)
        template
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def ensure_rubrics!(template)
      CATEGORIES.each_with_index do |(code, names), index|
        category = AssessmentCategory.find_or_create_by!(code:) do |record|
          record.name_ar, record.name_en = names
          record.display_order = index
          record.created_by = record.updated_by = @actor
        end
        rubric = template.rubric_items.find_or_initialize_by(assessment_category: category)
        rubric.assign_attributes(name_ar: names.first, name_en: names.last, scoring_type: "rating",
                                 maximum_score: 100, weight: 25, display_order: index)
        rubric.save!
      end
    end
  end
end
