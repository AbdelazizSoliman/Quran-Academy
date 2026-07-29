class StudentProfileEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated verified archived restored learning_status_changed student_type_changed self_updated
                   sensitive_information_updated].freeze

  belongs_to :student_profile, inverse_of: :events
  belongs_to :actor, class_name: "User", inverse_of: :student_profile_events
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
