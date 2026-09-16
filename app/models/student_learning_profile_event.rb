class StudentLearningProfileEvent < ApplicationRecord
  include SafeAuditMetadata

  ACTIONS = %w[profile_created section_created section_updated item_created item_updated].freeze
  SOURCES = %w[teacher_entry admin_entry observation].freeze

  belongs_to :student_learning_profile, inverse_of: :events
  belongs_to :section, class_name: "StudentLearningProfileSection",
                       foreign_key: :student_learning_profile_section_id, inverse_of: :events, optional: true
  belongs_to :item, class_name: "StudentLearningProfileItem",
                    foreign_key: :student_learning_profile_item_id, inverse_of: :events, optional: true
  belongs_to :actor, class_name: "User"

  attr_readonly :student_learning_profile_id, :student_learning_profile_section_id,
                :student_learning_profile_item_id, :actor_id, :action, :field_key, :previous_value,
                :new_value, :source, :metadata, :created_at

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  validates :action, inclusion: { in: ACTIONS }
  validates :source, inclusion: { in: SOURCES }
  validates :field_key, format: { with: StudentLearningProfileItem::FIELD_KEY_FORMAT }, allow_blank: true
  validate :related_records_belong_to_profile

  private

  def related_records_belong_to_profile
    if section && section.student_learning_profile_id != student_learning_profile_id
      errors.add(:section, :profile_mismatch)
    end
    return unless item && item.student_learning_profile.id != student_learning_profile_id

    errors.add(:item, :profile_mismatch)
  end

  def prevent_mutation
    errors.add(:base, :immutable)
    throw(:abort)
  end
end
