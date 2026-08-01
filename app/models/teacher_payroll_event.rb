class TeacherPayrollEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[generated prepared approved paid cancelled reopened adjusted].freeze

  belongs_to :teacher_payroll, inverse_of: :events
  belongs_to :actor, class_name: "User"

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
