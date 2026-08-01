class AccountInvitationEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created sent resent accepted expired cancelled].freeze

  belongs_to :account_invitation, inverse_of: :events
  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
