class StudentLearningProfileSection < ApplicationRecord
  COMPLETION_STATES = %w[not_started in_progress complete].freeze
  REVIEW_STATES = %w[unreviewed reviewed].freeze

  belongs_to :student_learning_profile, inverse_of: :sections
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :items, class_name: "StudentLearningProfileItem", inverse_of: :section, dependent: :restrict_with_exception
  has_many :events, class_name: "StudentLearningProfileEvent", inverse_of: :section, dependent: :restrict_with_exception

  validates :section_key, presence: true, inclusion: { in: StudentLearningProfileSectionRegistry.keys },
                          uniqueness: { scope: :student_learning_profile_id }
  validates :completion_state, inclusion: { in: COMPLETION_STATES }
  validates :review_state, inclusion: { in: REVIEW_STATES }
  validate :review_metadata_consistency

  def position = definition.fetch(:position)
  def importance = definition.fetch(:importance)

  private

  def definition = StudentLearningProfileSectionRegistry.fetch(section_key) || {}

  def review_metadata_consistency
    if review_state == "reviewed" && (reviewed_at.blank? || reviewed_by.blank?)
      errors.add(:review_state, :review_metadata_required)
    elsif review_state == "unreviewed" && (reviewed_at.present? || reviewed_by.present?)
      errors.add(:review_state, :review_metadata_not_allowed)
    end
  end
end
