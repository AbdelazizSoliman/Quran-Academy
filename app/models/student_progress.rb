class StudentProgress < ApplicationRecord
  TRENDS = %w[improving stable needs_attention].freeze

  belongs_to :student_profile
  belongs_to :strongest_category, class_name: "AssessmentCategory", optional: true
  belongs_to :weakest_category, class_name: "AssessmentCategory", optional: true
  belongs_to :latest_assessment, class_name: "StudentAssessment", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  validates :student_profile_id, uniqueness: true
  validates :trend, inclusion: { in: TRENDS }
  validates :current_page, numericality: { only_integer: true, in: 1..604 }, allow_nil: true
  validates :current_ayah, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :memorization_progress, :revision_progress, :completion_percentage,
            numericality: { in: 0..100 }
end
